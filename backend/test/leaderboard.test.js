/**
 * T113 — Global leaderboard endpoint tests.
 *
 * Verifies:
 *   - GET /leaderboard returns players sorted by rating descending
 *   - Includes player_id, username, rating, rank tier
 *   - Returns empty leaderboard when no players
 *   - Returns correct count
 */

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createLeaderboardRouter } = require('../routes/leaderboard');

// ── Mock pool ──────────────────────────────────────────────────────

let leaderboardData = [];

function mockQuery(sql, params) {
  if (sql.includes('SELECT l.player_id, a.username, l.rating, a.rank')) {
    const rows = leaderboardData
      .slice()
      .sort((a, b) => b.rating - a.rating)
      .map((p) => ({
        player_id: p.player_id,
        username: p.username,
        rating: p.rating,
        rank: p.rank,
      }));
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
  testApp.use('/leaderboard', createLeaderboardRouter(mockPool));

  await new Promise((resolve) => {
    server = testApp.listen(0, () => {
      baseUrl = `http://localhost:${server.address().port}`;
      resolve();
    });
  });

  // Seed test data
  leaderboardData = [
    { player_id: 1, username: 'Alice', rating: 1500, rank: 'Gold' },
    { player_id: 2, username: 'Bob', rating: 1200, rank: 'Silver' },
    { player_id: 3, username: 'Charlie', rating: 1800, rank: 'Platinum' },
    { player_id: 4, username: 'Diana', rating: 1000, rank: 'Silver' },
    { player_id: 5, username: 'Eve', rating: 3100, rank: 'Master' },
  ];
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

describe('GET /leaderboard', () => {
  it('returns players sorted by rating descending', async () => {
    const res = await get('/leaderboard');
    assert.equal(res.status, 200);
    assert.equal(res.body.leaderboard.length, 5);

    // Check order: Eve (3100) > Charlie (1800) > Alice (1500) > Bob (1200) > Diana (1000)
    assert.equal(res.body.leaderboard[0].username, 'Eve');
    assert.equal(res.body.leaderboard[0].rating, 3100);
    assert.equal(res.body.leaderboard[0].rankTier, 'Master');

    assert.equal(res.body.leaderboard[1].username, 'Charlie');
    assert.equal(res.body.leaderboard[1].rating, 1800);
    assert.equal(res.body.leaderboard[1].rankTier, 'Platinum');

    assert.equal(res.body.leaderboard[2].username, 'Alice');
    assert.equal(res.body.leaderboard[2].rating, 1500);

    assert.equal(res.body.leaderboard[3].username, 'Bob');
    assert.equal(res.body.leaderboard[3].rating, 1200);

    assert.equal(res.body.leaderboard[4].username, 'Diana');
    assert.equal(res.body.leaderboard[4].rating, 1000);
  });

  it('includes position numbers (1-indexed)', async () => {
    const res = await get('/leaderboard');
    assert.equal(res.body.leaderboard[0].rank, 1);
    assert.equal(res.body.leaderboard[1].rank, 2);
    assert.equal(res.body.leaderboard[2].rank, 3);
    assert.equal(res.body.leaderboard[3].rank, 4);
    assert.equal(res.body.leaderboard[4].rank, 5);
  });

  it('returns correct count', async () => {
    const res = await get('/leaderboard');
    assert.equal(res.body.count, 5);
  });

  it('each entry has playerId, username, rating, rankTier', async () => {
    const res = await get('/leaderboard');
    for (const entry of res.body.leaderboard) {
      assert.ok(entry.playerId, 'should have playerId');
      assert.ok(entry.username, 'should have username');
      assert.ok(typeof entry.rating === 'number', 'should have numeric rating');
      assert.ok(entry.rankTier, 'should have rankTier');
    }
  });

  it('returns empty leaderboard when no players', async () => {
    const saved = [...leaderboardData];
    leaderboardData = [];
    try {
      const res = await get('/leaderboard');
      assert.equal(res.status, 200);
      assert.equal(res.body.leaderboard.length, 0);
      assert.equal(res.body.count, 0);
    } finally {
      leaderboardData.splice(0, leaderboardData.length, ...saved);
    }
  });

  it('reflects rating changes when leaderboard refreshes', async () => {
    // Simulate a rating change
    leaderboardData[1].rating = 2000; // Bob goes from 1200 to 2000
    leaderboardData[1].rank = 'Gold';

    const res = await get('/leaderboard');
    // Bob should now be 2nd (2000), between Eve (3100) and Charlie (1800)
    assert.equal(res.body.leaderboard[1].username, 'Bob');
    assert.equal(res.body.leaderboard[1].rating, 2000);

    // Restore
    leaderboardData[1].rating = 1200;
    leaderboardData[1].rank = 'Silver';
  });
});
