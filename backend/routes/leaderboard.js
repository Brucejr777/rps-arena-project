/**
 * Leaderboard route (T113).
 *
 * GET /leaderboard — returns global leaderboard sorted by rating descending.
 *
 * The endpoint refreshes whenever the leaderboard screen opens (Flutter side).
 */

const { Router } = require('express');

function createLeaderboardRouter(pool) {
  const router = Router();

  // ── GET /leaderboard ──────────────────────────────────────────
  router.get('/', async (req, res) => {
    try {
      const result = await pool.query(
        `SELECT l.player_id, a.username, l.rating, a.rank
         FROM leaderboard l
         JOIN account a ON l.player_id = a.player_id
         ORDER BY l.rating DESC`
      );

      const leaderboard = result.rows.map((row, index) => ({
        rank: index + 1,
        playerId: row.player_id,
        username: row.username,
        rating: row.rating,
        rankTier: row.rank,
      }));

      res.json({ leaderboard, count: leaderboard.length });
    } catch (err) {
      console.error('Leaderboard error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

module.exports = { createLeaderboardRouter };
