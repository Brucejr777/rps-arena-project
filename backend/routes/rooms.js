/**
 * Private Room routes (T91).
 *
 * POST /rooms/create — create a private room with 6-char code
 * POST /rooms/join   — join an existing room by code (T93)
 * POST /rooms/start  — host starts the match (T95)
 */

const { Router } = require('express');
const { requireAuth } = require('../lib/auth_middleware');

const VALID_FORMATS = ['bestOf3', 'bestOf5', 'bestOf7', 'bestOf9', 'custom', 'unlimited'];
const CODE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const CODE_LENGTH = 6;

/**
 * Generate a random 6-character alphanumeric uppercase room code.
 */
function generateRoomCode() {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}

function createRoomsRouter(pool) {
  const router = Router();
  router.use(requireAuth);

  // ── POST /rooms/create ────────────────────────────────────────
  router.post('/create', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { formatType, winsRequired = 0 } = req.body;

      if (!formatType) {
        return res.status(400).json({ error: 'formatType is required.' });
      }

      if (!VALID_FORMATS.includes(formatType)) {
        return res.status(400).json({ error: 'Invalid format type.' });
      }

      // Validate custom wins_required (2–99)
      if (formatType === 'custom') {
        if (typeof winsRequired !== 'number' || winsRequired < 2 || winsRequired > 99) {
          return res.status(400).json({ error: 'Custom matches require winsRequired between 2 and 99.' });
        }
      }

      // Generate a unique 6-char code (retry on collision)
      let roomCode;
      let attempts = 0;
      const maxAttempts = 10;

      do {
        roomCode = generateRoomCode();
        const existing = await pool.query(
          'SELECT room_code FROM room WHERE room_code = $1',
          [roomCode]
        );
        if (existing.rows.length === 0) break;
        attempts++;
      } while (attempts < maxAttempts);

      if (attempts >= maxAttempts) {
        return res.status(500).json({ error: 'Failed to generate unique room code.' });
      }

      // Determine the actual wins_required value
      const actualWinsRequired = formatType === 'unlimited'
        ? 0
        : formatType === 'custom'
          ? winsRequired
          : { bestOf3: 2, bestOf5: 3, bestOf7: 4, bestOf9: 5 }[formatType];

      // Insert the room
      await pool.query(
        `INSERT INTO room (room_code, host_id, status, format_type, wins_required)
         VALUES ($1, $2, 'waiting', $3, $4)`,
        [roomCode, playerId, formatType, actualWinsRequired]
      );

      res.status(201).json({
        roomCode,
        formatType,
        winsRequired: actualWinsRequired,
        status: 'waiting',
        message: 'Room created. Share the code with your opponent.',
      });
    } catch (err) {
      console.error('Room create error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /rooms/join ──────────────────────────────────────────
  router.post('/join', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { roomCode } = req.body;

      if (!roomCode || roomCode.length !== CODE_LENGTH) {
        return res.status(400).json({ error: `Room code must be ${CODE_LENGTH} characters.` });
      }

      const result = await pool.query(
        'SELECT * FROM room WHERE room_code = $1',
        [roomCode.toUpperCase()]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Room not found.' });
      }

      const room = result.rows[0];

      if (room.status !== 'waiting') {
        return res.status(400).json({ error: 'Room is no longer accepting players.' });
      }

      if (room.host_id === playerId) {
        return res.status(400).json({ error: 'You cannot join your own room.' });
      }

      // Update the room with the guest
      await pool.query(
        `UPDATE room SET guest_id = $1, status = 'ready' WHERE room_code = $2`,
        [playerId, roomCode.toUpperCase()]
      );

      // Fetch host username
      const hostResult = await pool.query(
        'SELECT username FROM account WHERE player_id = $1',
        [room.host_id]
      );

      res.json({
        roomCode: roomCode.toUpperCase(),
        formatType: room.format_type,
        winsRequired: room.wins_required,
        hostName: hostResult.rows[0]?.username ?? 'Host',
        status: 'ready',
      });
    } catch (err) {
      console.error('Room join error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── POST /rooms/start ─────────────────────────────────────────
  router.post('/start', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { roomCode } = req.body;

      if (!roomCode) {
        return res.status(400).json({ error: 'roomCode is required.' });
      }

      const result = await pool.query(
        'SELECT * FROM room WHERE room_code = $1',
        [roomCode.toUpperCase()]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Room not found.' });
      }

      const room = result.rows[0];

      // Only the host can start
      if (room.host_id !== playerId) {
        return res.status(403).json({ error: 'Only the host can start the match.' });
      }

      // Both players must be joined
      if (!room.guest_id) {
        return res.status(400).json({ error: 'Waiting for a player to join.' });
      }

      if (room.status !== 'ready') {
        return res.status(400).json({ error: 'Room is not ready to start.' });
      }

      // Create the match record
      const matchResult = await pool.query(
        `INSERT INTO match (mode, format_type, wins_required, player_a_id, player_b_id)
         VALUES ('private', $1, $2, $3, $4)
         RETURNING match_id`,
        [room.format_type, room.wins_required, room.host_id, room.guest_id]
      );

      // Update room status
      await pool.query(
        `UPDATE room SET status = 'active' WHERE room_code = $1`,
        [roomCode.toUpperCase()]
      );

      res.json({
        matchId: matchResult.rows[0].match_id,
        formatType: room.format_type,
        winsRequired: room.wins_required,
        message: 'Match started!',
      });
    } catch (err) {
      console.error('Room start error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── GET /rooms/:code — poll room status ──────────────────────────
  router.get('/:code', async (req, res) => {
    try {
      const { code } = req.params;
      const result = await pool.query(
        `SELECT r.room_code, r.status, r.format_type, r.wins_required,
                r.host_id, r.guest_id,
                h.username AS host_name,
                g.username AS guest_name
         FROM room r
         LEFT JOIN account h ON r.host_id = h.player_id
         LEFT JOIN account g ON r.guest_id = g.player_id
         WHERE r.room_code = $1`,
        [code.toUpperCase()]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Room not found.' });
      }

      const room = result.rows[0];

      // If the room is active, fetch the latest private match between
      // host and guest so clients can navigate to gameplay.
      let matchId = null;
      if (room.status === 'active' && room.guest_id != null) {
        const matchResult = await pool.query(
          `SELECT match_id FROM match
           WHERE mode = 'private'
             AND player_a_id = $1
             AND player_b_id = $2
           ORDER BY match_id DESC
           LIMIT 1`,
          [room.host_id, room.guest_id]
        );
        if (matchResult.rows.length > 0) {
          matchId = matchResult.rows[0].match_id;
        }
      }

      res.json({
        roomCode: room.room_code,
        status: room.status,
        formatType: room.format_type,
        winsRequired: room.wins_required,
        hostName: room.host_name ?? 'Host',
        guestName: room.guest_name,
        hasGuest: room.guest_id != null,
        matchId,
      });
    } catch (err) {
      console.error('Room status error:', err);
      res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

module.exports = { createRoomsRouter, generateRoomCode, CODE_LENGTH };
