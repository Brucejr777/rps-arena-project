/**
 * Ranked Match routes (T96).
 *
 * POST /ranked/join  — enter ranked queue (fixed Best-of-3, wins_required 2)
 *
 * Ranked configuration (T96/T110-T112):
 *   - Fixed BEST_OF_3, wins_required 2
 *   - No match format selection
 *   - Rating change enabled (win +20, loss -20, draw 0)
 *   - Rank threshold update enabled
 *   - Global leaderboard update enabled
 *   - Competitive statistics recording enabled
 *   - Ranked match history recording enabled
 */

const { Router } = require('express');
const { requireAuth } = require('../lib/auth_middleware');
const { matchQueue } = require('../lib/match_queue');

const RANKED_FORMAT = 'bestOf3';
const RANKED_WINS_REQUIRED = 2;
const RATING_WIN = 20;
const RATING_LOSS = -20;
const RATING_DRAW = 0;
const RATING_FLOOR = 0;

const RANK_THRESHOLDS = [
  { rank: 'Master', minRating: 3000 },
  { rank: 'Diamond', minRating: 2500 },
  { rank: 'Platinum', minRating: 2000 },
  { rank: 'Gold', minRating: 1500 },
  { rank: 'Silver', minRating: 1000 },
  { rank: 'Bronze', minRating: 0 },
];

function getRankForRating(rating) {
  for (const tier of RANK_THRESHOLDS) {
    if (rating >= tier.minRating) return tier.rank;
  }
  return 'Bronze';
}

function createRankedRouter(pool) {
  const router = Router();
  router.use(requireAuth);

  // ── POST /ranked/join ────────────────────────────────────────
  router.post('/join', async (req, res) => {
    try {
      const { playerId, username } = req.player;

      // Fetch player rating
      const ratingResult = await pool.query(
        'SELECT rating FROM account WHERE player_id = $1',
        [playerId]
      );
      const rating = ratingResult.rows.length > 0 ? ratingResult.rows[0].rating : 1000;

      // Try to match in the ranked queue (same as bestOf3 queue)
      const match = matchQueue.join({
        playerId,
        username,
        rating,
        formatType: RANKED_FORMAT,
        winsRequired: RANKED_WINS_REQUIRED,
      });

      if (match) {
        const { player1, player2 } = match;

        const matchResult = await pool.query(
          `INSERT INTO match (mode, format_type, wins_required, player_a_id, player_b_id)
           VALUES ('ranked', $1, $2, $3, $4)
           RETURNING match_id`,
          [RANKED_FORMAT, RANKED_WINS_REQUIRED, player1.playerId, player2.playerId]
        );

        const matchId = matchResult.rows[0].match_id;

        res.json({
          status: 'matched',
          matchId,
          formatType: RANKED_FORMAT,
          winsRequired: RANKED_WINS_REQUIRED,
          opponent: {
            playerId: player2.playerId,
            username: player2.username,
            rating: player2.rating,
          },
        });
      } else {
        res.json({
          status: 'searching',
          formatType: RANKED_FORMAT,
          winsRequired: RANKED_WINS_REQUIRED,
          rating,
          message: 'SEARCHING FOR RANKED OPPONENT...',
        });
      }
    } catch (err) {
      console.error('Ranked join error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /ranked/cancel ──────────────────────────────────────
  router.delete('/cancel', (req, res) => {
    const { playerId } = req.player;
    const removed = matchQueue.cancel(playerId);
    res.json({ message: removed ? 'Ranked queue cancelled.' : 'No queue entry found.' });
  });

  return router;
}

module.exports = {
  createRankedRouter,
  RANKED_FORMAT,
  RANKED_WINS_REQUIRED,
  RATING_WIN,
  RATING_LOSS,
  RATING_DRAW,
  RATING_FLOOR,
  RANK_THRESHOLDS,
  getRankForRating,
};
