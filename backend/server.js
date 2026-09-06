require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');
const { Pool } = require('pg');
const { createAuthRouter } = require('./routes/auth');
const { createQuickMatchRouter } = require('./routes/quick_match');
const { createRoomsRouter } = require('./routes/rooms');
const { createRankedRouter } = require('./routes/ranked');
const { createMatchesRouter } = require('./routes/matches');
const { createLeaderboardRouter } = require('./routes/leaderboard');
const { disconnectManager } = require('./lib/disconnect_manager');

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Auto-migrate: ensure all tables and columns exist
(async () => {
  try {
    // Ensure refresh_token table exists
    await pool.query(`
      CREATE TABLE IF NOT EXISTS refresh_token (
        token_hash TEXT PRIMARY KEY,
        player_id INTEGER NOT NULL REFERENCES account(player_id),
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    `);
    console.log('Migration: refresh_token table ready');

    // Fix legacy column name: rename 'token' → 'token_hash' if needed
    await pool.query(`
      DO $$ BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns WHERE table_name = 'refresh_token' AND column_name = 'token'
        ) AND NOT EXISTS (
          SELECT 1 FROM information_schema.columns WHERE table_name = 'refresh_token' AND column_name = 'token_hash'
        ) THEN
          ALTER TABLE refresh_token RENAME COLUMN token TO token_hash;
          RAISE NOTICE 'Migration: renamed refresh_token.token to token_hash';
        END IF;
      END $$;
    `);
    console.log('Migration: refresh_token column name checked');

    // Ensure result columns are TEXT
    await pool.query(`
      DO $$ BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns WHERE table_name = 'round' AND column_name = 'result' AND data_type != 'text'
        ) THEN
          ALTER TABLE round ALTER COLUMN result TYPE TEXT;
        END IF;
      END $$;
    `);
    await pool.query(`
      DO $$ BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns WHERE table_name = 'match_history' AND column_name = 'result' AND data_type != 'text'
        ) THEN
          ALTER TABLE match_history ALTER COLUMN result TYPE TEXT;
        END IF;
      END $$;
    `);
    console.log('Migration: result columns checked');

    // Ensure match_history rank_change column exists
    await pool.query(`
      DO $$ BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns WHERE table_name = 'match_history' AND column_name = 'rank_change'
        ) THEN
          ALTER TABLE match_history ADD COLUMN rank_change VARCHAR(20);
        END IF;
      END $$;
    `);
    console.log('Migration: match_history rank_change checked');

    // Ensure unique constraint on (match_id, round_number)
    await pool.query(`
      DO $$ BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'round_match_number_key'
        ) THEN
          ALTER TABLE round ADD CONSTRAINT round_match_number_key
            UNIQUE (match_id, round_number);
        END IF;
      END $$;
    `);
    console.log('Migration: round unique constraint ready');
  } catch (err) {
    console.error('Migration warning:', err.message);
  }
})();

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', createAuthRouter(pool));
app.use('/quick-match', createQuickMatchRouter(pool));
app.use('/rooms', createRoomsRouter(pool));
app.use('/ranked', createRankedRouter(pool));
app.use('/leaderboard', createLeaderboardRouter(pool));

// Create HTTP server for WebSocket
const server = http.createServer(app);

// WebSocket server
const wss = new WebSocketServer({ server });

// Track connections: Map<matchId, Map<playerId, WebSocket>>
const matchConnections = new Map();

// Register match routes with wss and matchConnections for targeted delivery
app.use('/matches', createMatchesRouter(pool, wss, matchConnections));

// WebSocket connection handler
wss.on('connection', (ws, req) => {
  // Extract matchId from URL: /matches/{matchId}/events?playerId=X
  const urlParts = req.url.split('/');
  const matchId = parseInt(urlParts[2]);
  const playerId = parseInt(new URL(req.url, 'http://localhost').searchParams.get('playerId'));

  if (!matchId || !playerId) {
    ws.close(4000, 'Invalid matchId or playerId');
    return;
  }

  // Track this connection (overwrites any old WS for this player — handles reconnects)
  if (!matchConnections.has(matchId)) {
    matchConnections.set(matchId, new Map());
  }
  matchConnections.get(matchId).set(playerId, ws);

  console.log(`Player ${playerId} connected to match ${matchId} (ws id=${ws._ulid || 'n/a'})`);

  // Cancel any disconnect timer (reconnected successfully)
  const wasDisconnected = disconnectManager.cancelDisconnect(matchId, playerId);
  if (wasDisconnected) {
    console.log(`Player ${playerId} reconnected to match ${matchId}`);

    // Notify opponent that player reconnected
    const matchConns = matchConnections.get(matchId);
    for (const [pId, client] of matchConns) {
      if (pId !== playerId && client.readyState === 1) {
        client.send(JSON.stringify({ type: 'opponent_connected', matchId, playerId }));
      }
    }
  }

  // If both players are now connected, send round_start to synchronize timers
  const matchConns = matchConnections.get(matchId);
  if (matchConns && matchConns.size >= 2) {
    const roundStartPayload = JSON.stringify({
      type: 'round_start',
      matchId,
      serverTime: Date.now(),
    });
    for (const [, client] of matchConns) {
      if (client.readyState === 1) {
        client.send(roundStartPayload);
      }
    }
    console.log(`Both players connected for match ${matchId} — sent round_start`);
  }

  ws.on('close', () => {
    console.log(`Player ${playerId} disconnected from match ${matchId}`);

    // Remove from tracking — but ONLY if this ws is still the active one.
    // If the player reconnected, a newer ws is stored and we must not delete it.
    const matchConns = matchConnections.get(matchId);
    if (matchConns && matchConns.get(playerId) === ws) {
      matchConns.delete(playerId);
      if (matchConns.size === 0) {
        matchConnections.delete(matchId);
      }
    } else {
      console.log(`Player ${playerId} close ignored — newer connection exists in match ${matchId}`);
    }

    // Start 30s disconnect window if match is active
    handleDisconnect(matchId, playerId);
  });

  ws.on('error', (err) => {
    console.error(`WebSocket error for player ${playerId} in match ${matchId}:`, err.message);
  });
});

/**
 * Handle player disconnect — start 30s reconnect window.
 */
async function handleDisconnect(matchId, playerId) {
  try {
    const matchResult = await pool.query(
      'SELECT * FROM match WHERE match_id = $1',
      [matchId]
    );

    if (matchResult.rows.length === 0) return;
    const match = matchResult.rows[0];

    // Don't start timer if match is already finished
    if (match.winner_id || match.match_draw) return;

    const isPlayerA = match.player_a_id === playerId;
    const isPlayerB = match.player_b_id === playerId;
    if (!isPlayerA && !isPlayerB) return;

    console.log(`Starting 30s reconnect window for player ${playerId} in match ${matchId}`);

    disconnectManager.startDisconnect(matchId, playerId, isPlayerA, async ({ matchId: mId, playerId: pId, isPlayerA: pIsA }) => {
      console.log(`Player ${pId} failed to reconnect — assigning loss`);
      try {
        const winnerId = pIsA ? match.player_b_id : match.player_a_id;
        await pool.query('UPDATE match SET winner_id = $1 WHERE match_id = $2', [winnerId, mId]);

        // Notify opponent
        const matchConns = matchConnections.get(mId);
        if (matchConns) {
          for (const [pid, client] of matchConns) {
            if (client.readyState === 1) {
              client.send(JSON.stringify({
                type: 'match_completed',
                matchId: mId, winnerId,
                reason: 'opponent_disconnected',
                message: 'Opponent disconnected — you win!',
              }));
              client.send(JSON.stringify({
                type: 'opponent_disconnected',
                matchId: mId, playerId: pId,
              }));
            }
          }
        }
      } catch (err) {
        console.error('Disconnect timeout handler error:', err);
      }
    });

    // Notify opponent immediately
    const matchConns = matchConnections.get(matchId);
    if (matchConns) {
      for (const [pId, client] of matchConns) {
        if (pId !== playerId && client.readyState === 1) {
          client.send(JSON.stringify({
            type: 'opponent_disconnected',
            matchId, playerId, reconnectWindow: 30,
          }));
        }
      }
    }
  } catch (err) {
    console.error('Handle disconnect error:', err);
  }
}

// Auto-initialize database schema on startup
async function initDatabase() {
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    const statements = schema.split(';').map(s => s.trim()).filter(s => s.length > 0);
    for (const stmt of statements) {
      await pool.query(stmt);
    }
    console.log(`Database initialized: ${statements.length} tables created/verified.`);
  } catch (err) {
    console.error('Database init error:', err.message);
  }
}

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  initDatabase().then(() => {
    server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  });
}

module.exports = { app, pool, server, wss, matchConnections };