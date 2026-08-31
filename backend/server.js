require('dotenv').config();
const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const { Pool } = require('pg');
const { createAuthRouter } = require('./routes/auth');
const { createQuickMatchRouter } = require('./routes/quick_match');
const { createRoomsRouter } = require('./routes/rooms');
const { createRankedRouter } = require('./routes/ranked');
const { createMatchesRouter } = require('./routes/matches');
const { disconnectManager } = require('./lib/disconnect_manager');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', createAuthRouter(pool));
app.use('/quick-match', createQuickMatchRouter(pool));
app.use('/rooms', createRoomsRouter(pool));
app.use('/ranked', createRankedRouter(pool));

// Create HTTP server for WebSocket
const server = http.createServer(app);

// WebSocket server
const wss = new WebSocketServer({ server });

// Track connections: Map<matchId, Map<playerId, WebSocket>>
const matchConnections = new Map();

// Register match routes with wss
app.use('/matches', createMatchesRouter(pool, wss));

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

  // Track this connection
  if (!matchConnections.has(matchId)) {
    matchConnections.set(matchId, new Map());
  }
  matchConnections.get(matchId).set(playerId, ws);

  console.log(`Player ${playerId} connected to match ${matchId}`);

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

  ws.on('close', () => {
    console.log(`Player ${playerId} disconnected from match ${matchId}`);

    // Remove from tracking
    const matchConns = matchConnections.get(matchId);
    if (matchConns) {
      matchConns.delete(playerId);
      if (matchConns.size === 0) {
        matchConnections.delete(matchId);
      }
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

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = { app, pool, server, wss, matchConnections };