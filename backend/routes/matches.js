/**
 * Match routes (T97).
 *
 * POST /matches/:matchId/move — submit a move (server-authoritative)
 * GET  /matches/:matchId/state — get current match state
 * POST /matches/:matchId/end  — end Unlimited match (T102)
 *
 * Server-authoritative round:
 *   - Validates move as ROCK, PAPER, SCISSORS
 *   - Validates player is in the match
 *   - Stores selection in round table
 *   - Rejects late / duplicate submissions
 *   - After both submissions: resolves, updates score, checks completion
 *   - Sends round_result via WebSocket (when connected)
 */

const { Router } = require('express');
const { requireAuth } = require('../lib/auth_middleware');
const { resolveRound } = require('../lib/resolution');

const VALID_MOVES = ['rock', 'paper', 'scissors'];

function createMatchesRouter(pool, wss) {
  const router = Router();
  router.use(requireAuth);

  // ── POST /matches/:matchId/move ──────────────────────────────
  router.post('/:matchId/move', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { matchId } = req.params;
      const { move } = req.body;

      // Validate move
      if (!move || !VALID_MOVES.includes(move)) {
        return res.status(400).json({ error: 'Move must be rock, paper, or scissors.' });
      }

      // Fetch match
      const matchResult = await pool.query(
        'SELECT * FROM match WHERE match_id = $1',
        [matchId]
      );

      if (matchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Match not found.' });
      }

      const match = matchResult.rows[0];

      // Check match is still active
      if (match.winner_id || match.match_draw) {
        return res.status(400).json({ error: 'Match is already finished.' });
      }

      // Verify player is in this match
      const isPlayerA = match.player_a_id === playerId;
      const isPlayerB = match.player_b_id === playerId;
      if (!isPlayerA && !isPlayerB) {
        return res.status(403).json({ error: 'You are not part of this match.' });
      }

      // Determine current round number
      const roundResult = await pool.query(
        'SELECT MAX(round_number) as max_round FROM round WHERE match_id = $1',
        [matchId]
      );
      const currentRound = (roundResult.rows[0].max_round || 0) + 1;

      // Check for existing round this player already submitted to
      const existingRound = await pool.query(
        `SELECT id, player_a_move, player_b_move FROM round
         WHERE match_id = $1 AND round_number = $2`,
        [matchId, currentRound]
      );

      let roundId;
      let existingMove = null;

      if (existingRound.rows.length === 0) {
        // Create new round
        const insertResult = await pool.query(
          `INSERT INTO round (match_id, round_number, player_a_move, player_b_move, player_a_auto, player_b_auto)
           VALUES ($1, $2, $3, $4, false, false)
           RETURNING id`,
          [matchId, currentRound, isPlayerA ? move : null, isPlayerB ? move : null]
        );
        roundId = insertResult.rows[0].id;
      } else {
        // Round exists — check if this player already submitted
        const round = existingRound.rows[0];
        roundId = round.id;

        if (isPlayerA && round.player_a_move) {
          return res.status(400).json({ error: 'You have already submitted a move for this round.' });
        }
        if (isPlayerB && round.player_b_move) {
          return res.status(400).json({ error: 'You have already submitted a move for this round.' });
        }

        // Store this player's move
        if (isPlayerA) {
          await pool.query('UPDATE round SET player_a_move = $1 WHERE id = $2', [move, roundId]);
        } else {
          await pool.query('UPDATE round SET player_b_move = $1 WHERE id = $2', [move, roundId]);
        }

        existingMove = isPlayerA ? round.player_a_move : round.player_b_move;
      }

      // Check if both players have submitted
      const updatedRound = await pool.query(
        'SELECT player_a_move, player_b_move FROM round WHERE id = $1',
        [roundId]
      );
      const round = updatedRound.rows[0];

      if (!round.player_a_move || !round.player_b_move) {
        // Still waiting for the other player
        return res.json({
          status: 'waiting',
          roundNumber: currentRound,
          message: 'Waiting for opponent...',
        });
      }

      // Both moves submitted — resolve the round
      const result = resolveRound(round.player_a_move, round.player_b_move);

      // Update round result
      await pool.query('UPDATE round SET result = $1 WHERE id = $2', [result, roundId]);

      // Update match score
      let playerAScore = match.total_rounds > 0
        ? (await pool.query(
            `SELECT COUNT(*) as wins FROM round WHERE match_id = $1 AND result = 'player_a_wins'`,
            [matchId]
          )).rows[0].wins
        : 0;
      let playerBScore = match.total_rounds > 0
        ? (await pool.query(
            `SELECT COUNT(*) as wins FROM round WHERE match_id = $1 AND result = 'player_b_wins'`,
            [matchId]
          )).rows[0].wins
        : 0;

      // Add this round's result
      if (result === 'player_a_wins') playerAScore = parseInt(playerAScore) + 1;
      if (result === 'player_b_wins') playerBScore = parseInt(playerBScore) + 1;

      const newDrawCount = result === 'draw'
        ? match.draw_count + 1
        : match.draw_count;

      const newTotalRounds = match.total_rounds + 1;

      // Update match totals
      await pool.query(
        `UPDATE match SET total_rounds = $1, draw_count = $2 WHERE match_id = $3`,
        [newTotalRounds, newDrawCount, matchId]
      );

      // Check match completion (standard formats only — Unlimited handled by /end)
      let matchFinished = false;
      let matchWinner = null;

      if (match.format_type !== 'unlimited') {
        if (playerAScore >= match.wins_required) {
          matchFinished = true;
          matchWinner = match.player_a_id;
        } else if (playerBScore >= match.wins_required) {
          matchFinished = true;
          matchWinner = match.player_b_id;
        }
      }

      if (matchFinished) {
        await pool.query(
          'UPDATE match SET winner_id = $1 WHERE match_id = $2',
          [matchWinner, matchId]
        );
      }

      // Build WebSocket event payload
      const eventPayload = {
        type: 'round_result',
        matchId: parseInt(matchId),
        roundNumber: currentRound,
        playerAMove: round.player_a_move,
        playerBMove: round.player_b_move,
        result,
        playerAScore,
        playerBScore,
        drawCount: newDrawCount,
        totalRounds: newTotalRounds,
        matchFinished,
        winnerId: matchWinner,
      };

      // Broadcast to match participants via WebSocket
      if (wss) {
        const message = JSON.stringify(eventPayload);
        wss.clients.forEach((client) => {
          if (client.readyState === 1) { // WebSocket.OPEN
            client.send(message);
          }
        });
      }

      res.json(eventPayload);
    } catch (err) {
      console.error('Move submission error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── GET /matches/:matchId/state ───────────────────────────────
  router.get('/:matchId/state', async (req, res) => {
    try {
      const { matchId } = req.params;

      const matchResult = await pool.query(
        'SELECT * FROM match WHERE match_id = $1',
        [matchId]
      );

      if (matchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Match not found.' });
      }

      const match = matchResult.rows[0];

      const roundsResult = await pool.query(
        'SELECT * FROM round WHERE match_id = $1 ORDER BY round_number',
        [matchId]
      );

      // Calculate current scores from rounds
      let playerAScore = 0;
      let playerBScore = 0;
      for (const round of roundsResult.rows) {
        if (round.result === 'player_a_wins') playerAScore++;
        if (round.result === 'player_b_wins') playerBScore++;
      }

      res.json({
        matchId: match.match_id,
        formatType: match.format_type,
        winsRequired: match.wins_required,
        playerAId: match.player_a_id,
        playerBId: match.player_b_id,
        playerAScore,
        playerBScore,
        drawCount: match.draw_count,
        totalRounds: match.total_rounds,
        winnerId: match.winner_id,
        matchDraw: match.match_draw,
        rounds: roundsResult.rows.map((r) => ({
          roundNumber: r.round_number,
          playerAMove: r.player_a_move,
          playerBMove: r.player_b_move,
          result: r.result,
        })),
      });
    } catch (err) {
      console.error('Match state error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

module.exports = { createMatchesRouter };
