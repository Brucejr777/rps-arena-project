/**
 * Auth routes for RPS Arena (T80).
 *
 * POST /auth/register   — create account, return tokens
 * POST /auth/login      — verify credentials, return tokens
 * POST /auth/logout     — invalidate refresh token
 * POST /auth/refresh    — exchange refresh token for new access token
 * GET  /auth/profile     — get player profile and stats (T116)
 */

const { Router } = require('express');
const { validateUsername } = require('../lib/validate_username');
const { validatePassword } = require('../lib/validate_password');
const { hashPassword, verifyPassword } = require('../lib/hash_password');
const { requireAuth } = require('../lib/auth_middleware');
const {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} = require('../lib/tokens');

// Refresh token helpers — persisted in database to survive server restarts.
async function storeRefreshToken(pool, token, playerId) {
  await pool.query('INSERT INTO refresh_token (token_hash, player_id) VALUES ($1, $2)', [token, playerId]);
}

async function hasRefreshToken(pool, token) {
  const result = await pool.query('SELECT 1 FROM refresh_token WHERE token_hash = $1', [token]);
  return result.rows.length > 0;
}

async function deleteRefreshToken(pool, token) {
  await pool.query('DELETE FROM refresh_token WHERE token_hash = $1', [token]);
}

async function deleteRefreshTokensForPlayer(pool, playerId) {
  await pool.query('DELETE FROM refresh_token WHERE player_id = $1', [playerId]);
}

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
      await storeRefreshToken(pool, refreshToken, player.player_id);

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
      console.error('Register error:', err.message, err.stack);
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
      await storeRefreshToken(pool, refreshToken, player.player_id);

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
      console.error('Login error:', err.message, err.stack);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /auth/logout ────────────────────────────────────────────
  router.post('/logout', async (req, res) => {
    const { refreshToken } = req.body;

    if (refreshToken) {
      await deleteRefreshToken(pool, refreshToken);
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
      if (!(await hasRefreshToken(pool, refreshToken))) {
        return res.status(401).json({ error: 'Invalid refresh token.' });
      }

      let payload;
      try {
        payload = verifyRefreshToken(refreshToken);
      } catch {
        await deleteRefreshToken(pool, refreshToken);
        return res.status(401).json({ error: 'Invalid refresh token.' });
      }

      // Fetch current player data (rating may have changed)
      const result = await pool.query(
        'SELECT player_id, username, rating, rank FROM account WHERE player_id = $1',
        [payload.playerId]
      );

      if (result.rows.length === 0) {
        await deleteRefreshToken(pool, refreshToken);
        return res.status(401).json({ error: 'Player not found.' });
      }

      const player = result.rows[0];

      // Rotate: invalidate old refresh token, issue new pair
      await deleteRefreshToken(pool, refreshToken);

      const newAccessToken = signAccessToken(player.player_id, player.username);
      const newRefreshToken = signRefreshToken(player.player_id);
      await storeRefreshToken(pool, newRefreshToken, player.player_id);

      res.json({
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      });
    } catch (err) {
      console.error('Refresh error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── GET /auth/profile (T116) ────────────────────────────────────
  router.get('/profile', requireAuth, async (req, res) => {
    try {
      const { playerId } = req.player;

      // Fetch player info
      const playerResult = await pool.query(
        'SELECT player_id, username, rating, rank FROM account WHERE player_id = $1',
        [playerId]
      );

      if (playerResult.rows.length === 0) {
        return res.status(404).json({ error: 'Player not found.' });
      }

      const player = playerResult.rows[0];

      // Fetch player statistics
      const statsResult = await pool.query(
        'SELECT * FROM player_statistic WHERE player_id = $1',
        [playerId]
      );

      const stats = statsResult.rows[0] || {
        matches_played: 0,
        matches_won: 0,
        matches_lost: 0,
        rounds_won: 0,
        rounds_lost: 0,
        draws: 0,
        rock_selections: 0,
        paper_selections: 0,
        scissors_selections: 0,
      };

      const winRate = stats.matches_played > 0
        ? Math.round((stats.matches_won / stats.matches_played) * 100)
        : 0;

      res.json({
        player: {
          playerId: player.player_id,
          username: player.username,
          rating: player.rating,
          rank: player.rank,
        },
        stats: {
          matchesPlayed: stats.matches_played,
          matchesWon: stats.matches_won,
          matchesLost: stats.matches_lost,
          roundsWon: stats.rounds_won,
          roundsLost: stats.rounds_lost,
          draws: stats.draws,
          winRate,
          rockSelections: stats.rock_selections,
          paperSelections: stats.paper_selections,
          scissorsSelections: stats.scissors_selections,
        },
      });
    } catch (err) {
      console.error('Profile error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── GET /auth/statistics (T121) ─────────────────────────────────
  router.get('/statistics', requireAuth, async (req, res) => {
    try {
      const { playerId } = req.player;

      const statsResult = await pool.query(
        'SELECT * FROM player_statistic WHERE player_id = $1',
        [playerId]
      );

      const s = statsResult.rows[0] || {
        matches_played: 0, matches_won: 0, matches_lost: 0,
        rounds_won: 0, rounds_lost: 0, draws: 0,
        rock_selections: 0, paper_selections: 0, scissors_selections: 0,
      };

      const winRate = s.matches_played > 0
        ? Math.round((s.matches_won / s.matches_played) * 100)
        : 0;

      res.json({
        matchesPlayed: s.matches_played,
        matchesWon: s.matches_won,
        matchesLost: s.matches_lost,
        roundsWon: s.rounds_won,
        roundsLost: s.rounds_lost,
        draws: s.draws,
        winRate,
        rockSelections: s.rock_selections,
        paperSelections: s.paper_selections,
        scissorsSelections: s.scissors_selections,
      });
    } catch (err) {
      console.error('Statistics error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

module.exports = { createAuthRouter };
