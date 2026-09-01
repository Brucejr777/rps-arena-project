/**
 * Auth routes for RPS Arena (T80).
 *
 * POST /auth/register   — create account, return tokens
 * POST /auth/login      — verify credentials, return tokens
 * POST /auth/logout     — invalidate refresh token
 * POST /auth/refresh    — exchange refresh token for new access token
 */

const { Router } = require('express');
const { validateUsername } = require('../lib/validate_username');
const { validatePassword } = require('../lib/validate_password');
const { hashPassword, verifyPassword } = require('../lib/hash_password');
const {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} = require('../lib/tokens');

// In-memory refresh token store.
// Maps refresh token string -> playerId (for logout invalidation).
// Production would use a database table or Redis.
const refreshTokens = new Map();

function createAuthRouter(pool) {
  const router = Router();

  // ── POST /auth/register ──────────────────────────────────────────
  router.post('/register', async (req, res) => {
    try {
      const { username, password } = req.body;

      if (!username || !password) {
        return res
          .status(400)
          .json({ error: 'Username and password are required.' });
      }

      const usernameCheck = validateUsername(username);
      if (!usernameCheck.valid) {
        return res.status(400).json({ error: usernameCheck.error });
      }

      const passwordCheck = validatePassword(password);
      if (!passwordCheck.valid) {
        return res.status(400).json({ error: passwordCheck.error });
      }

      // Check uniqueness
      const existing = await pool.query(
        'SELECT player_id FROM account WHERE username = $1',
        [username]
      );
      if (existing.rows.length > 0) {
        return res.status(409).json({ error: 'Username already taken.' });
      }

      const passwordHash = await hashPassword(password);

      const result = await pool.query(
        `INSERT INTO account (username, password_hash)
         VALUES ($1, $2)
         RETURNING player_id, username, rating, rank`,
        [username, passwordHash]
      );

      const player = result.rows[0];

      // Create initial player_statistic row
      await pool.query(
        'INSERT INTO player_statistic (player_id) VALUES ($1)',
        [player.player_id]
      );

      // Create initial leaderboard entry with default rating 1000
      await pool.query(
        'INSERT INTO leaderboard (player_id, rating) VALUES ($1, $2)',
        [player.player_id, player.rating]
      );

      const accessToken = signAccessToken(player.player_id, player.username);
      const refreshToken = signRefreshToken(player.player_id);
      refreshTokens.set(refreshToken, player.player_id);

      res.status(201).json({
        player: {
          playerId: player.player_id,
          username: player.username,
          rating: player.rating,
          rank: player.rank,
        },
        accessToken,
        refreshToken,
      });
    } catch (err) {
      console.error('Register error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /auth/login ─────────────────────────────────────────────
  router.post('/login', async (req, res) => {
    try {
      const { username, password } = req.body;

      if (!username || !password) {
        return res
          .status(400)
          .json({ error: 'Username and password are required.' });
      }

      const result = await pool.query(
        'SELECT player_id, username, password_hash, rating, rank FROM account WHERE username = $1',
        [username]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid username or password.' });
      }

      const player = result.rows[0];
      const match = await verifyPassword(password, player.password_hash);

      if (!match) {
        return res.status(401).json({ error: 'Invalid username or password.' });
      }

      const accessToken = signAccessToken(player.player_id, player.username);
      const refreshToken = signRefreshToken(player.player_id);
      refreshTokens.set(refreshToken, player.player_id);

      res.json({
        player: {
          playerId: player.player_id,
          username: player.username,
          rating: player.rating,
          rank: player.rank,
        },
        accessToken,
        refreshToken,
      });
    } catch (err) {
      console.error('Login error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /auth/logout ────────────────────────────────────────────
  router.post('/logout', (req, res) => {
    const { refreshToken } = req.body;

    if (refreshToken) {
      refreshTokens.delete(refreshToken);
    }

    res.json({ message: 'Logged out.' });
  });

  // ── POST /auth/refresh ───────────────────────────────────────────
  router.post('/refresh', async (req, res) => {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({ error: 'Refresh token required.' });
      }

      // Check if token has been invalidated (logged out)
      if (!refreshTokens.has(refreshToken)) {
        return res.status(401).json({ error: 'Invalid refresh token.' });
      }

      let payload;
      try {
        payload = verifyRefreshToken(refreshToken);
      } catch {
        refreshTokens.delete(refreshToken);
        return res.status(401).json({ error: 'Invalid refresh token.' });
      }

      // Fetch current player data (rating may have changed)
      const result = await pool.query(
        'SELECT player_id, username, rating, rank FROM account WHERE player_id = $1',
        [payload.playerId]
      );

      if (result.rows.length === 0) {
        refreshTokens.delete(refreshToken);
        return res.status(401).json({ error: 'Player not found.' });
      }

      const player = result.rows[0];

      // Rotate: invalidate old refresh token, issue new pair
      refreshTokens.delete(refreshToken);

      const newAccessToken = signAccessToken(player.player_id, player.username);
      const newRefreshToken = signRefreshToken(player.player_id);
      refreshTokens.set(newRefreshToken, player.player_id);

      res.json({
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      });
    } catch (err) {
      console.error('Refresh error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

// Export the Map so tests can inspect/seed it
module.exports = { createAuthRouter, _refreshTokens: refreshTokens };
