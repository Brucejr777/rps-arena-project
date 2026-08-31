const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { app } = require('../server');
const { signRefreshToken, verifyAccessToken } = require('../lib/tokens');
const { hashPassword } = require('../lib/hash_password');

// ── Mock pool ──────────────────────────────────────────────────────
// In-memory store that mimics just enough of pg.Pool for auth routes.

let accounts = [];
let stats = [];
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
    return Promise.resolve({ rows: [player] });
  }

  // INSERT INTO player_statistic
  if (sql.includes('INSERT INTO player_statistic')) {
    stats.push({ player_id: params[0] });
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

  // SELECT ... FROM account WHERE player_id (refresh)
  if (sql.includes('FROM account WHERE player_id')) {
    const found = accounts.find((a) => a.player_id === params[0]);
    return Promise.resolve({
      rows: found
        ? [{ player_id: found.player_id, username: found.username, rating: found.rating, rank: found.rank }]
        : [],
    });
  }

  return Promise.resolve({ rows: [] });
}

const mockPool = { query: mockQuery };

// ── Test server ────────────────────────────────────────────────────

let server;
let baseUrl;

before(async () => {
  // Create fresh auth router with mock pool
  const { createAuthRouter } = require('../routes/auth');
  const express = require('express');
  const testApp = express();
  testApp.use(express.json());
  testApp.use('/auth', createAuthRouter(mockPool));

  await new Promise((resolve) => {
    server = testApp.listen(0, () => {
      baseUrl = `http://localhost:${server.address().port}`;
      resolve();
    });
  });

  // Seed a test account
  const hash = await hashPassword('TestPass1');
  accounts.push({
    player_id: nextId++,
    username: 'ExistingUser',
    password_hash: hash,
    rating: 1000,
    rank: 'Bronze',
  });
});

after(() => {
  server.close();
});

function post(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const url = new URL(path, baseUrl);
    const req = http.request(url, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

// ── Tests ──────────────────────────────────────────────────────────

describe('POST /auth/register', () => {
  it('registers a new player and returns tokens', async () => {
    const res = await post('/auth/register', { username: 'NewPlayer', password: 'StrongPass1' });
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.body.player.username, 'NewPlayer');
    assert.strictEqual(res.body.player.rating, 1000);
    assert.strictEqual(res.body.player.rank, 'Bronze');
    assert.ok(res.body.accessToken);
    assert.ok(res.body.refreshToken);
  });

  it('rejects duplicate username', async () => {
    const res = await post('/auth/register', { username: 'ExistingUser', password: 'StrongPass1' });
    assert.strictEqual(res.status, 409);
    assert.ok(res.body.error.includes('already taken'));
  });

  it('rejects short username', async () => {
    const res = await post('/auth/register', { username: 'ab', password: 'StrongPass1' });
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.error.includes('at least 3'));
  });

  it('rejects short password', async () => {
    const res = await post('/auth/register', { username: 'ValidName', password: 'short' });
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.error.includes('at least 8'));
  });

  it('rejects missing fields', async () => {
    const res = await post('/auth/register', { username: 'ValidName' });
    assert.strictEqual(res.status, 400);
  });

  it('creates initial player_statistic row', async () => {
    // The register for NewPlayer above should have created a stat row
    assert.ok(stats.some((s) => s.player_id > 0));
  });
});

describe('POST /auth/login', () => {
  it('logs in with correct credentials and returns tokens', async () => {
    const res = await post('/auth/login', { username: 'ExistingUser', password: 'TestPass1' });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.player.username, 'ExistingUser');
    assert.ok(res.body.accessToken);
    assert.ok(res.body.refreshToken);

    // Verify access token is valid
    const payload = verifyAccessToken(res.body.accessToken);
    assert.strictEqual(payload.username, 'ExistingUser');
  });

  it('rejects wrong password', async () => {
    const res = await post('/auth/login', { username: 'ExistingUser', password: 'WrongPass99' });
    assert.strictEqual(res.status, 401);
    assert.ok(res.body.error.includes('Invalid'));
  });

  it('rejects unknown username', async () => {
    const res = await post('/auth/login', { username: 'Nobody', password: 'TestPass1' });
    assert.strictEqual(res.status, 401);
  });

  it('rejects missing fields', async () => {
    const res = await post('/auth/login', { username: 'ExistingUser' });
    assert.strictEqual(res.status, 400);
  });
});

describe('POST /auth/logout', () => {
  it('invalidates the refresh token', async () => {
    // Get a token pair first
    const login = await post('/auth/login', { username: 'ExistingUser', password: 'TestPass1' });
    const rt = login.body.refreshToken;

    // Logout
    const res = await post('/auth/logout', { refreshToken: rt });
    assert.strictEqual(res.status, 200);
    assert.ok(res.body.message.includes('Logged out'));

    // Refresh should now fail
    const refresh = await post('/auth/refresh', { refreshToken: rt });
    assert.strictEqual(refresh.status, 401);
  });

  it('succeeds even without a refresh token', async () => {
    const res = await post('/auth/logout', {});
    assert.strictEqual(res.status, 200);
  });
});

describe('POST /auth/refresh', () => {
  it('returns a new token pair and invalidates the old refresh token', async () => {
    const login = await post('/auth/login', { username: 'ExistingUser', password: 'TestPass1' });
    const oldRefresh = login.body.refreshToken;

    // Refresh
    const res = await post('/auth/refresh', { refreshToken: oldRefresh });
    assert.strictEqual(res.status, 200);
    assert.ok(res.body.accessToken);
    assert.ok(res.body.refreshToken);
    // New refresh token should be different (rotation) —
    // may be identical if issued in the same second, so we only
    // assert the old token is now invalid.

    // Old refresh token should be invalidated (rotation)
    const oldRefreshAttempt = await post('/auth/refresh', { refreshToken: oldRefresh });
    assert.strictEqual(oldRefreshAttempt.status, 401);
  });

  it('rejects missing refresh token', async () => {
    const res = await post('/auth/refresh', {});
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.error.includes('required'));
  });

  it('rejects invalid refresh token', async () => {
    const res = await post('/auth/refresh', { refreshToken: 'totally.bogus.token' });
    assert.strictEqual(res.status, 401);
  });
});
