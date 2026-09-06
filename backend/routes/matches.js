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
const { roundTimeoutManager } = require('../lib/round_timeout');
const { calculateRatingChanges, applyRatingChanges, updatePlayerStatistics, trackMoveSelection, recordMatchHistory } = require('../lib/rating');

const VALID_MOVES = ['rock', 'paper', 'scissors'];

function createMatchesRouter(pool, wss, matchConnections) {
  const router = Router();
  router.use(requireAuth);

  /** Send to both participants in a match via their tracked WS connections. */
  function broadcastToMatch(matchId, payload) {
    const msg = JSON.stringify(payload);
    let sent = 0;
    if (matchConnections) {
      const conns = matchConnections.get(matchId);
      if (conns) {
        console.log(`broadcastToMatch: matchId=${matchId}, conns=${conns.size}, type=${payload.type}`);
        for (const [pid, client] of conns) {
          if (client.readyState === 1) {
            client.send(msg);
            sent++;
          } else {
            console.log(`broadcastToMatch: player ${pid} readyState=${client.readyState} (not OPEN)`);
          }
        }
        console.log(`broadcastToMatch: sent to ${sent}/${conns.size} clients`);
      } else {
        console.log(`broadcastToMatch: no conns entry for matchId=${matchId}`);
      }
    }
    // Always fall back to wss.clients if no targeted clients received it
    if (sent === 0 && wss) {
      console.log(`broadcastToMatch: fallback to wss.clients, total=${wss.clients.size}`);
      wss.clients.forEach((c) => { if (c.readyState === 1) c.send(msg); });
    }
  }

  // ── GET /matches/history (T118) ──────────────────────────────
  router.get('/history', async (req, res) => {
    try {
      const { playerId } = req.player;

      const result = await pool.query(
        `SELECT mh.history_id, mh.match_id, mh.opponent_id, a.username AS opponent_name,
                mh.mode, mh.format_type, mh.result, mh.rating_before, mh.rating_after,
                mh.rank_change, mh.created_at
         FROM match_history mh
         JOIN account a ON mh.opponent_id = a.player_id
         WHERE mh.player_id = $1
         ORDER BY mh.created_at DESC
         LIMIT 50`,
        [playerId]
      );

      res.json({ history: result.rows, count: result.rows.length });
    } catch (err) {
      console.error('Match history error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

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
        // Create new round — use ON CONFLICT to handle the race where both
        // players submit at the same instant and both read "no row".
        const insertResult = await pool.query(
          `INSERT INTO round (match_id, round_number, player_a_move, player_b_move, player_a_auto, player_b_auto)
           VALUES ($1, $2, $3, $4, false, false)
           ON CONFLICT (match_id, round_number) DO NOTHING
           RETURNING id`,
          [matchId, currentRound, isPlayerA ? move : null, isPlayerB ? move : null]
        );

        if (insertResult.rows.length > 0) {
          // We won the race — we created the row.
          roundId = insertResult.rows[0].id;

          // Start 10s timeout for the other player (T100)
          const waitingPlayerId = isPlayerA ? match.player_b_id : match.player_a_id;
          const waitingIsPlayerA = !isPlayerA;
          roundTimeoutManager.startTimer(parseInt(matchId), currentRound, waitingPlayerId, waitingIsPlayerA);
        } else {
          // Another player created the row between our SELECT and INSERT.
          // Fall through to the "round exists" branch below.
          const retryRound = await pool.query(
            `SELECT id, player_a_move, player_b_move FROM round
             WHERE match_id = $1 AND round_number = $2`,
            [matchId, currentRound]
          );
          existingRound.rows = retryRound.rows;
          // Fall through
        }
      }

      if (existingRound.rows.length > 0 && roundId == null) {
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

      // Both moves submitted — cancel timeout and resolve (T100)
      roundTimeoutManager.cancelTimer(parseInt(matchId), currentRound);

      // T117: Track move selections for both players
      await trackMoveSelection(pool, match.player_a_id, round.player_a_move);
      await trackMoveSelection(pool, match.player_b_id, round.player_b_move);

      const result = resolveRound(round.player_a_move, round.player_b_move);

      // Update match score — query BEFORE setting the round result to avoid
      // double-counting the current round. pg COUNT returns strings, so
      // coerce to numbers.
      const countWins = async (resultType) => {
        const r = await pool.query(
          `SELECT COUNT(*) as wins FROM round WHERE match_id = $1 AND result = $2`,
          [matchId, resultType]
        );
        return parseInt(r.rows[0].wins, 10) || 0;
      };
      let playerAScore = await countWins('player_a_wins');
      let playerBScore = await countWins('player_b_wins');

      // Add this round's result
      if (result === 'player_a_wins') playerAScore += 1;
      if (result === 'player_b_wins') playerBScore += 1;

      // Update round result (AFTER counting to avoid double-count)
      await pool.query('UPDATE round SET result = $1 WHERE id = $2', [result, roundId]);

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

        // T111/T117/T118: Apply rating changes for ranked matches (records history)
        if (match.mode === 'ranked') {
          const { ratingChangeA, ratingChangeB } = calculateRatingChanges(false, matchWinner, match.player_a_id, match.player_b_id);
          await applyRatingChanges(pool, matchId, match.player_a_id, match.player_b_id, ratingChangeA, ratingChangeB);
        } else if (match.mode !== 'local') {
          // T118: Record match history for non-ranked online matches
          await recordMatchHistory(pool, matchId, match.player_a_id, match.player_b_id, false, matchWinner, playerAScore, playerBScore);
        }

        // T117: Update statistics for ALL online match modes
        if (match.mode !== 'local') {
          await updatePlayerStatistics(pool, match.player_a_id, match.player_b_id, false, matchWinner, playerAScore, playerBScore);
        }
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
      if (wss || matchConnections) {
        console.log(`Broadcasting round_result for match ${matchId} round ${currentRound}: ${result} (scores ${playerAScore}-${playerBScore})`);
        broadcastToMatch(parseInt(matchId), eventPayload);

        // T101: send dedicated match_completed event when match finishes
        if (matchFinished) {
          const completedPayload = {
            type: 'match_completed',
            matchId: parseInt(matchId),
            winnerId: matchWinner,
            playerAScore,
            playerBScore,
            drawCount: newDrawCount,
            totalRounds: newTotalRounds,
            formatType: match.format_type,
            winsRequired: match.wins_required,
          };
          broadcastToMatch(parseInt(matchId), completedPayload);
        } else {
          // Send round_start after 1.5s so both players begin the next
          // round together (1s reveal + 0.5s grace for WS delivery).
          setTimeout(() => {
            broadcastToMatch(parseInt(matchId), {
              type: 'round_start',
              matchId: parseInt(matchId),
              serverTime: Date.now(),
            });
          }, 1500);
        }
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

  // ── POST /matches/:matchId/end (T102) ────────────────────────
  router.post('/:matchId/end', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { matchId } = req.params;

      // Fetch match
      const matchResult = await pool.query(
        'SELECT * FROM match WHERE match_id = $1',
        [matchId]
      );

      if (matchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Match not found.' });
      }

      const match = matchResult.rows[0];

      // Must be an Unlimited match
      if (match.format_type !== 'unlimited') {
        return res.status(400).json({ error: 'End is only available for Unlimited matches.' });
      }

      // Match must not already be finished
      if (match.winner_id || match.match_draw) {
        return res.status(400).json({ error: 'Match is already finished.' });
      }

      // Verify player is in this match
      const isPlayerA = match.player_a_id === playerId;
      const isPlayerB = match.player_b_id === playerId;
      if (!isPlayerA && !isPlayerB) {
        return res.status(403).json({ error: 'You are not part of this match.' });
      }

      // Must have at least one completed round
      if (match.total_rounds < 1) {
        return res.status(400).json({ error: 'Must complete at least one round before ending.' });
      }

      // If there's an in-progress round with one move submitted, complete it first
      const currentRoundNum = await pool.query(
        'SELECT MAX(round_number) as max_round FROM round WHERE match_id = $1',
        [matchId]
      );
      const latestRound = currentRoundNum.rows[0]?.max_round || 0;

      if (latestRound > 0) {
        const roundCheck = await pool.query(
          'SELECT id, player_a_move, player_b_move, result FROM round WHERE match_id = $1 AND round_number = $2',
          [matchId, latestRound]
        );

        if (roundCheck.rows.length > 0) {
          const r = roundCheck.rows[0];
          // If one player submitted but round isn't resolved yet, auto-complete it
          if (!r.result && ((r.player_a_move && !r.player_b_move) || (!r.player_a_move && r.player_b_move))) {
            const missingIsA = !r.player_a_move;
            const autoMove = ['rock', 'paper', 'scissors'][Math.floor(Math.random() * 3)];

            if (missingIsA) {
              await pool.query('UPDATE round SET player_a_move = $1, player_a_auto = true WHERE id = $2', [autoMove, r.id]);
            } else {
              await pool.query('UPDATE round SET player_b_move = $1, player_b_auto = true WHERE id = $2', [autoMove, r.id]);
            }

            // Resolve the round
            const updated = await pool.query('SELECT player_a_move, player_b_move FROM round WHERE id = $1', [r.id]);
            const result = resolveRound(updated.rows[0].player_a_move, updated.rows[0].player_b_move);
            await pool.query('UPDATE round SET result = $1 WHERE id = $2', [result, r.id]);

            const newTotalRounds = match.total_rounds + 1;
            const newDrawCount = result === 'draw' ? match.draw_count + 1 : match.draw_count;
            await pool.query('UPDATE match SET total_rounds = $1, draw_count = $2 WHERE match_id = $3', [newTotalRounds, newDrawCount, matchId]);
            match.total_rounds = newTotalRounds;
            match.draw_count = newDrawCount;
          }
        }
      }

      // Calculate final scores (pg COUNT returns strings — coerce to numbers)
      const aWins = parseInt((await pool.query(
        `SELECT COUNT(*) as c FROM round WHERE match_id = $1 AND result = 'player_a_wins'`, [matchId]
      )).rows[0].c, 10) || 0;
      const bWins = parseInt((await pool.query(
        `SELECT COUNT(*) as c FROM round WHERE match_id = $1 AND result = 'player_b_wins'`, [matchId]
      )).rows[0].c, 10) || 0;

      // Determine winner
      let winnerId = null;
      let matchDraw = false;

      if (aWins > bWins) {
        winnerId = match.player_a_id;
      } else if (bWins > aWins) {
        winnerId = match.player_b_id;
      } else {
        matchDraw = true;
      }

      // Update match
      await pool.query(
        'UPDATE match SET winner_id = $1, match_draw = $2 WHERE match_id = $3',
        [winnerId, matchDraw, matchId]
      );

      // T111/T117/T118: Apply rating changes for ranked matches (records history)
      if (match.mode === 'ranked') {
        const { ratingChangeA, ratingChangeB } = calculateRatingChanges(matchDraw, winnerId, match.player_a_id, match.player_b_id);
        await applyRatingChanges(pool, matchId, match.player_a_id, match.player_b_id, ratingChangeA, ratingChangeB);
      } else if (match.mode !== 'local') {
        // T118: Record match history for non-ranked online matches
        await recordMatchHistory(pool, matchId, match.player_a_id, match.player_b_id, matchDraw, winnerId, aWins, bWins);
      }

      // T117: Update statistics for ALL online match modes
      if (match.mode !== 'local') {
        await updatePlayerStatistics(pool, match.player_a_id, match.player_b_id, matchDraw, winnerId, aWins, bWins);
      }

      // Send match_completed via WebSocket
      if (wss || matchConnections) {
        broadcastToMatch(parseInt(matchId), {
          type: 'match_completed',
          matchId: parseInt(matchId),
          winnerId,
          matchDraw,
          playerAScore: aWins,
          playerBScore: bWins,
          drawCount: match.draw_count,
          totalRounds: match.total_rounds,
          formatType: 'unlimited',
          winsRequired: 0,
        });
      }

      res.json({
        matchId: parseInt(matchId),
        winnerId,
        matchDraw,
        playerAScore: aWins,
        playerBScore: bWins,
        drawCount: match.draw_count,
        totalRounds: match.total_rounds,
        message: matchDraw ? 'Match Draw.' : 'Match finished!',
      });
    } catch (err) {
      console.error('Match end error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /matches/:matchId/cancel (T107) ──────────────────
  router.post('/:matchId/cancel', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { matchId } = req.params;

      // Fetch match
      const matchResult = await pool.query(
        'SELECT * FROM match WHERE match_id = $1',
        [matchId]
      );

      if (matchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Match not found.' });
      }

      const match = matchResult.rows[0];

      // Match must not already be finished
      if (match.winner_id || match.match_draw) {
        return res.status(400).json({ error: 'Match is already finished.' });
      }

      // Verify player is in this match
      const isPlayerA = match.player_a_id === playerId;
      const isPlayerB = match.player_b_id === playerId;
      if (!isPlayerA && !isPlayerB) {
        return res.status(403).json({ error: 'You are not part of this match.' });
      }

      // For ranked matches: cancel after ready triggers loss penalty
      if (match.mode === 'ranked') {
        // Both players are in the match (ready confirmed) — penalty applies
        const winnerId = isPlayerA ? match.player_b_id : match.player_a_id;
        const loserId = playerId;

        // Update match with loss
        await pool.query(
          'UPDATE match SET winner_id = $1, total_rounds = total_rounds + 1 WHERE match_id = $2',
          [winnerId, matchId]
        );

        // T111: Apply rating changes for ranked cancel
        const { ratingChangeA: cancelRatingA, ratingChangeB: cancelRatingB } = calculateRatingChanges(false, winnerId, match.player_a_id, match.player_b_id);
        await applyRatingChanges(pool, matchId, match.player_a_id, match.player_b_id, cancelRatingA, cancelRatingB);
        await updatePlayerStatistics(pool, match.player_a_id, match.player_b_id, false, winnerId, 0, 0);

        // Send match_completed via WebSocket
        if (wss || matchConnections) {
          broadcastToMatch(parseInt(matchId), {
            type: 'match_completed',
            matchId: parseInt(matchId),
            winnerId,
            reason: 'cancel',
            message: 'Opponent cancelled the ranked match.',
            formatType: match.format_type,
            winsRequired: match.wins_required,
          });
        }

        return res.json({
          matchId: parseInt(matchId),
          winnerId,
          loserId,
          penalty: true,
          message: 'Ranked match cancelled. Loss recorded.',
        });
      }

      // Non-ranked match: simple cancel without penalty
      await pool.query(
        'UPDATE match SET match_draw = true WHERE match_id = $1',
        [matchId]
      );

      // T118: Record match history for non-ranked cancel
      await recordMatchHistory(pool, matchId, match.player_a_id, match.player_b_id, true, null, 0, 0);

      // T117: Update stats for non-ranked online matches on cancel
      await updatePlayerStatistics(pool, match.player_a_id, match.player_b_id, true, null, 0, 0);

      // Send match_completed via WebSocket
      if (wss || matchConnections) {
        broadcastToMatch(parseInt(matchId), {
          type: 'match_completed',
          matchId: parseInt(matchId),
          winnerId: null,
          matchDraw: true,
          reason: 'cancel',
          message: 'Match cancelled.',
          formatType: match.format_type,
          winsRequired: match.wins_required,
        });
      }

      res.json({
        matchId: parseInt(matchId),
        penalty: false,
        message: 'Match cancelled.',
      });
    } catch (err) {
      console.error('Match cancel error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /matches/:matchId/quit (T106) ────────────────────
  router.post('/:matchId/quit', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { matchId } = req.params;

      // Fetch match
      const matchResult = await pool.query(
        'SELECT * FROM match WHERE match_id = $1',
        [matchId]
      );

      if (matchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Match not found.' });
      }

      const match = matchResult.rows[0];

      // Match must not already be finished
      if (match.winner_id || match.match_draw) {
        return res.status(400).json({ error: 'Match is already finished.' });
      }

      // Verify player is in this match
      const isPlayerA = match.player_a_id === playerId;
      const isPlayerB = match.player_b_id === playerId;
      if (!isPlayerA && !isPlayerB) {
        return res.status(403).json({ error: 'You are not part of this match.' });
      }

      // Must be a ranked match to use quit penalty
      if (match.mode !== 'ranked') {
        return res.status(400).json({ error: 'Quit penalty only applies to ranked matches.' });
      }

      // Determine winner (opponent) and loser (quitter)
      const winnerId = isPlayerA ? match.player_b_id : match.player_a_id;
      const loserId = playerId;

      // Update match: set winner, increment total rounds for record
      await pool.query(
        'UPDATE match SET winner_id = $1, total_rounds = total_rounds + 1 WHERE match_id = $2',
        [winnerId, matchId]
      );

      // T111: Apply rating changes for ranked quit
      const { ratingChangeA: quitRatingA, ratingChangeB: quitRatingB } = calculateRatingChanges(false, winnerId, match.player_a_id, match.player_b_id);
      await applyRatingChanges(pool, matchId, match.player_a_id, match.player_b_id, quitRatingA, quitRatingB);

      // Send match_completed via WebSocket
      if (wss || matchConnections) {
        broadcastToMatch(parseInt(matchId), {
          type: 'match_completed',
          matchId: parseInt(matchId),
          winnerId,
          reason: 'quit',
          message: 'Opponent quit the match.',
          formatType: match.format_type,
          winsRequired: match.wins_required,
        });
      }

      res.json({
        matchId: parseInt(matchId),
        winnerId,
        loserId,
        message: 'Match quit. Loss recorded.',
      });
    } catch (err) {
      console.error('Match quit error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── Round timeout handler (T100) ─────────────────────────────
  roundTimeoutManager.onTimeout(async ({ matchId, roundNumber, playerId, isPlayerA, autoMove }) => {
    try {
      // Check if round still needs this move
      const roundResult = await pool.query(
        `SELECT id, player_a_move, player_b_move FROM round
         WHERE match_id = $1 AND round_number = $2`,
        [matchId, roundNumber]
      );

      if (roundResult.rows.length === 0) return;
      const round = roundResult.rows[0];

      // Player already submitted — nothing to do
      if (isPlayerA && round.player_a_move) return;
      if (!isPlayerA && round.player_b_move) return;

      // Assign random move and mark AUTO
      if (isPlayerA) {
        await pool.query(
          'UPDATE round SET player_a_move = $1, player_a_auto = true WHERE id = $2',
          [autoMove, round.id]
        );
      } else {
        await pool.query(
          'UPDATE round SET player_b_move = $1, player_b_auto = true WHERE id = $2',
          [autoMove, round.id]
        );
      }

      // T117: Track auto-move selection
      await trackMoveSelection(pool, playerId, autoMove);

      // Now resolve the round as if both submitted
      const updatedRound = await pool.query(
        'SELECT player_a_move, player_b_move FROM round WHERE id = $1',
        [round.id]
      );
      const r = updatedRound.rows[0];
      if (!r.player_a_move || !r.player_b_move) return;

      const result = resolveRound(r.player_a_move, r.player_b_move);
      await pool.query('UPDATE round SET result = $1 WHERE id = $2', [result, round.id]);

      // Fetch match for score calculation
      const matchResult = await pool.query('SELECT * FROM match WHERE match_id = $1', [matchId]);
      const match = matchResult.rows[0];
      if (!match) return;

      // Update match totals
      const newTotalRounds = match.total_rounds + 1;
      const newDrawCount = result === 'draw' ? match.draw_count + 1 : match.draw_count;
      await pool.query(
        'UPDATE match SET total_rounds = $1, draw_count = $2 WHERE match_id = $3',
        [newTotalRounds, newDrawCount, matchId]
      );

      // Calculate scores
      const aWins = (await pool.query(
        `SELECT COUNT(*) as c FROM round WHERE match_id = $1 AND result = 'player_a_wins'`, [matchId]
      )).rows[0].c;
      const bWins = (await pool.query(
        `SELECT COUNT(*) as c FROM round WHERE match_id = $1 AND result = 'player_b_wins'`, [matchId]
      )).rows[0].c;

      // Check match completion
      let matchFinished = false;
      let matchWinner = null;
      if (match.format_type !== 'unlimited') {
        if (aWins >= match.wins_required) { matchFinished = true; matchWinner = match.player_a_id; }
        else if (bWins >= match.wins_required) { matchFinished = true; matchWinner = match.player_b_id; }
      }
      if (matchFinished) {
        await pool.query('UPDATE match SET winner_id = $1 WHERE match_id = $2', [matchWinner, matchId]);

        // T111/T117/T118: Apply rating changes for ranked matches (records history)
        if (match.mode === 'ranked') {
          const { ratingChangeA, ratingChangeB } = calculateRatingChanges(false, matchWinner, match.player_a_id, match.player_b_id);
          await applyRatingChanges(pool, matchId, match.player_a_id, match.player_b_id, ratingChangeA, ratingChangeB);
        } else if (match.mode !== 'local') {
          // T118: Record match history for non-ranked online matches
          await recordMatchHistory(pool, matchId, match.player_a_id, match.player_b_id, false, matchWinner, parseInt(aWins), parseInt(bWins));
        }

        // T117: Update statistics for ALL online match modes
        if (match.mode !== 'local') {
          await updatePlayerStatistics(pool, match.player_a_id, match.player_b_id, false, matchWinner, parseInt(aWins), parseInt(bWins));
        }
      }

      // Broadcast via WebSocket
      if (wss || matchConnections) {
        broadcastToMatch(matchId, {
          type: 'round_result',
          matchId,
          roundNumber,
          playerAMove: r.player_a_move,
          playerBMove: r.player_b_move,
          result,
          playerAScore: aWins,
          playerBScore: bWins,
          drawCount: newDrawCount,
          totalRounds: newTotalRounds,
          matchFinished,
          winnerId: matchWinner,
          autoMove: true,
        });
      }
    } catch (err) {
      console.error('Round timeout error:', err);
    }
  });

  return router;
}

module.exports = { createMatchesRouter };
