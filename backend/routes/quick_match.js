/**
 * Quick Match routes (T87).
 *
 * POST   /quick-match/join    — enter the queue for a format
 * DELETE /quick-match/cancel  — leave the queue
 * POST   /quick-match/ready   — confirm readiness after opponent found
 */

const { Router } = require('express');
const { requireAuth } = require('../lib/auth_middleware');
const { matchQueue } = require('../lib/match_queue');

function createQuickMatchRouter(pool) {
  const router = Router();

  // All quick-match routes require authentication
  router.use(requireAuth);

  // ── POST /quick-match/join ────────────────────────────────────
  router.post('/join', async (req, res) => {
    try {
      const { playerId, username } = req.player;
      const { formatType, winsRequired = 0 } = req.body;

      if (!formatType) {
        return res.status(400).json({ error: 'formatType is required.' });
      }

      const validFormats = ['bestOf3', 'bestOf5', 'bestOf7', 'bestOf9', 'custom', 'unlimited'];
      if (!validFormats.includes(formatType)) {
        return res.status(400).json({ error: 'Invalid format type.' });
      }

      // Fetch player rating
      const ratingResult = await pool.query(
        'SELECT rating FROM account WHERE player_id = $1',
        [playerId]
      );
      const rating = ratingResult.rows.length > 0 ? ratingResult.rows[0].rating : 1000;

      // Try to match
      const match = matchQueue.join({
        playerId,
        username,
        rating,
        formatType,
        winsRequired: formatType === 'unlimited' ? 0 : winsRequired,
      });

      if (match) {
        // Matched! Create a match record and room
        const { player1, player2 } = match;

        const matchResult = await pool.query(
          `INSERT INTO match (mode, format_type, wins_required, player_a_id, player_b_id)
           VALUES ('casual', $1, $2, $3, $4)
           RETURNING match_id`,
          [formatType, winsRequired, player1.playerId, player2.playerId]
        );

        const matchId = matchResult.rows[0].match_id;

        res.json({
          status: 'matched',
          matchId,
          opponent: {
            playerId: player2.playerId,
            username: player2.username,
            rating: player2.rating,
          },
        });
      } else {
        // Enqueued — waiting for opponent
        res.json({
          status: 'searching',
          formatType,
          winsRequired,
          rating,
          message: 'SEARCHING FOR OPPONENT...',
        });
      }
    } catch (err) {
      console.error('Quick match join error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── DELETE /quick-match/cancel ────────────────────────────────
  router.delete('/cancel', (req, res) => {
    const { playerId } = req.player;
    const removed = matchQueue.cancel(playerId);

    res.json({
      message: removed ? 'Queue entry cancelled.' : 'No queue entry found.',
    });
  });

  // ── POST /quick-match/ready ───────────────────────────────────
  // After opponent is found, both players must confirm readiness
  // within 15 seconds or the match is cancelled.
  router.post('/ready', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { matchId } = req.body;

      if (!matchId) {
        return res.status(400).json({ error: 'matchId is required.' });
      }

      // Verify the player is part of this match
      const matchResult = await pool.query(
        'SELECT player_a_id, player_b_id FROM match WHERE match_id = $1',
        [matchId]
      );

      if (matchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Match not found.' });
      }

      const match = matchResult.rows[0];
      if (match.player_a_id !== playerId && match.player_b_id !== playerId) {
        return res.status(403).json({ error: 'You are not part of this match.' });
      }

      // TODO T89: implement full ready-up tracking with 15s timeout
      // For now, acknowledge readiness
      res.json({ status: 'ready', matchId });
    } catch (err) {
      console.error('Quick match ready error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

module.exports = { createQuickMatchRouter };
