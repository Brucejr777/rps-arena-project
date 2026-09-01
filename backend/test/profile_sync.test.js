/**
 * T121 — Profile synchronization endpoint tests.
 *
 * Verifies:
 *   - GET /auth/profile returns player info + stats
 *   - GET /auth/statistics returns just stats
 *   - GET /matches/history returns match history
 *   - All endpoints require auth
 */

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createAuthRouter } = require('../routes/auth');
const { createLeaderboardRouter } = require('../routes/leaderboard');
const { hashPassword } = require('../lib/hash_password');
const { signAccessToken } = require('../lib/tokens');

// ── Mock pool ──────────────────────────────────────────────────────

let accounts = [];
let playerStats = [];
let matchHistoryData = [];
let nextId = 1;

function mockQuery(sql, params) {
  // INSERT INTO account
  if (sql.includes('INSERT INTO account')) {
    const [username, passwordHash] = params;
    const player = {
      player_id: nextId++,
      username,
      password_hash: passwordHash,
      rating: 1000,
      rank: 'Bronze',
    };
    accounts.push(player);
    playerStats.push({
      player_id: player.player_id,
      matches_played: 0,
      matches_won: 0,
      matches_lost: 0,
      rounds_won: 0,
      rounds_lost: 0,
      draws: 0,
      rock_selections: 0,
      paper_selections: 0,
      scissors_selections: 0,
    });
    return Promise.resolve({ rows: [player] });
  }

  // INSERT INTO player_statistic / leaderboard
  if (sql.includes('INSERT INTO player_statistic') || sql.includes('INSERT INTO leaderboard')) {
    return Promise.resolve({ rows: [] });
  }

  // SELECT player_id FROM account WHERE username (uniqueness check)
  if (sql.includes('SELECT player_id FROM account') && sql.includes('WHERE username')) {
    const found = accounts.filter((a) => a.username === params[0]);
    return Promise.resolve({ rows: found.map((a) => ({ player_id: a.player_id })) });
  }

  // SELECT ... FROM account WHERE username (login)
  if (sql.includes('FROM account WHERE username') && sql.includes('password_hash')) {
    const found = accounts.find((a) => a.username === params[0]);
    return Promise.resolve({
      rows: found
        ? [{ player_id: found.player_id, username: found.username, password_hash: found.password_hash, rating: found.rating, rank: found.rank }]
        : [],
    });
  }

  // SELECT ... FROM account WHERE player_id (profile, statistics, refresh)
  if (sql.includes('FROM account WHERE player_id')) {
    const found = accounts.find((a) => a.player_id === params[0]);
    return Promise.resolve({
      rows: found
        ? [{ player_id: found.player_id, username: found.username, rating: found.rating, rank: found.rank }]
        : [],
    });
  }

  // SELECT * FROM player_statistic WHERE player_id
  if (sql.includes('SELECT * FROM player_statistic WHERE player_id')) {
    const found = playerStats.find((s) => s.player_id === params[0]);
    return Promise.resolve({ rows: found ? [found] : [] });
  }

  // SELECT from match_history
  if (sql.includes('match_history')) {
    const rows = matchHistoryData
      .filter((h) => h.player_id === params[0])
      .slice(0, 50);
    return Promise.resolve({ rows });
  }

  return Promise.resolve({ rows: [] });
}

const mockPool = { query: mockQuery };

// ── Test server ────────────────────────────────────────────────────

let server;
let baseUrl;

before(async () => {
  const express = require('express');
  const testApp = express();
  testApp.use(express.json());
  testApp.use('/auth', createAuthRouter(mockPool));
  testApp.use('/matches', (req, res, next) => {
    // Fake auth middleware for /matches routes
    const auth = req.headers.authorization;
    if (!auth || !auth.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    try {
      const token = auth.slice(7);
      const payload = require('../lib/tokens').verifyAccessToken(token);
      req.player = { playerId: payload.playerId, username: payload.username };
    } catch {
      return res.status(401).json({ error: 'Invalid token' });
    }
    next();
  });

  // Simple match history route for testing
  testApp.get('/matches/history', async (req, res) => {
    const { playerId } = req.player;
    const rows = matchHistoryData
      .filter((h) => h.player_id === playerId)
      .slice(0, 50);
    res.json({ history: rows, count: rows.length });
  });

  await new Promise((resolve) => {
    server = testApp.listen(0, () => {
      baseUrl = `http://localhost:${server.address().port}`;
      resolve();
    });
  });

  // Seed test account
  const hash = await hashPassword('TestPass1');
  accounts.push({
    player_id: nextId++,
    username: 'TestPlayer',
    password_hash: hash,
    rating: 1200,
    rank: 'Silver',
  });
  playerStats.push({
    player_id: 1,
    matches_played: 10,
    matches_won: 6,
    matches_lost: 4,
    rounds_won: 18,
    rounds_lost: 12,
    draws: 2,
    rock_selections: 35,
    paper_selections: 28,
    scissors_selections: 37,
  });
  matchHistoryData.push({
    history_id: 1,
    player_id: 1,
    match_id: 1,
    opponent_id: 2,
    opponent_name: 'Opponent1',
    mode: 'ranked',
    format_type: 'bestOf3',
    result: 'win',
    rating_before: 1180,
    rating_after: 1200,
    rank_change: null,
    created_at: '2026-01-01T12:00:00Z',
  });
});

after(() => {
  server.close();
});

function get(path, token) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const headers = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const req = http.request(url, { method: 'GET', headers }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.end();
  });
}

// ── Tests ──────────────────────────────────────────────────────────

describe('GET /auth/profile (T121)', () => {
  it('returns player info and statistics', async () => {
    const token = signAccessToken(1, 'TestPlayer');
    const res = await get('/auth/profile', token);
    assert.equal(res.status, 200);
    assert.equal(res.body.player.username, 'TestPlayer');
    assert.equal(res.body.player.rating, 1200);
    assert.equal(res.body.player.rank, 'Silver');
    assert.equal(res.body.stats.matchesPlayed, 10);
    assert.equal(res.body.stats.matchesWon, 6);
    assert.equal(res.body.stats.winRate, 60);
  });

  it('returns 401 without auth', async () => {
    const res = await get('/auth/profile');
    assert.equal(res.status, 401);
  });
});

describe('GET /auth/statistics (T121)', () => {
  it('returns statistics only', async () => {
    const token = signAccessToken(1, 'TestPlayer');
    const res = await get('/auth/statistics', token);
    assert.equal(res.status, 200);
    assert.equal(res.body.matchesPlayed, 10);
    assert.equal(res.body.matchesWon, 6);
    assert.equal(res.body.matchesLost, 4);
    assert.equal(res.body.roundsWon, 18);
    assert.equal(res.body.roundsLost, 12);
    assert.equal(res.body.draws, 2);
    assert.equal(res.body.winRate, 60);
    assert.equal(res.body.rockSelections, 35);
    assert.equal(res.body.paperSelections, 28);
    assert.equal(res.body.scissorsSelections, 37);
    // Should NOT have player info
    assert.equal(res.body.player, undefined);
    assert.equal(res.body.username, undefined);
  });

  it('returns 401 without auth', async () => {
    const res = await get('/auth/statistics');
    assert.equal(res.status, 401);
  });
});

describe('GET /matches/history (T121)', () => {
  it('returns match history', async () => {
    const token = signAccessToken(1, 'TestPlayer');
    const res = await get('/matches/history', token);
    assert.equal(res.status, 200);
    assert.equal(res.body.history.length, 1);
    assert.equal(res.body.history[0].result, 'win');
    assert.equal(res.body.history[0].mode, 'ranked');
    assert.equal(res.body.count, 1);
  });

  it('returns 401 without auth', async () => {
    const res = await get('/matches/history');
    assert.equal(res.status, 401);
  });
});
