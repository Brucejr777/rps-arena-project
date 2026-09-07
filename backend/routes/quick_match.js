/**
 * Quick Match routes (T87/T89).
 *
 * POST   /quick-match/join    — enter the queue for a format
 * GET    /quick-match/status  — poll queue / ready-up / confirmed state
 * DELETE /quick-match/cancel  — leave the queue or cancel pending ready-up
 * POST   /quick-match/ready   — confirm readiness after opponent found
 *
 * IMPORTANT:
 * - Quick Match uses the in-memory MatchQueue.
 * - It is separate from Private Rooms.
 * - Quick Match search will NEVER match Private Room entries.
 */

const { Router } = require('express');
const { requireAuth } = require('../lib/auth_middleware');
const { matchQueue } = require('../lib/match_queue');
const { readyUpManager } = require('../lib/ready_up_manager');

const VALID_FORMATS = [
  'bestOf3',
  'bestOf5',
  'bestOf7',
  'bestOf9',
  'custom',
  'unlimited',
];

const STANDARD_WINS_REQUIRED = {
  bestOf3: 2,
  bestOf5: 3,
  bestOf7: 4,
  bestOf9: 5,
};

/**
 * Confirmed matches are kept briefly in memory so both clients can poll
 * /quick-match/status and discover that the match is ready to start.
 *
 * This is needed because the player who pressed READY first receives
 * "waiting" from POST /quick-match/ready, then must learn via polling
 * that the second player also pressed READY.
 */
const CONFIRMED_STATUS_TTL_MS = 120_000;
const confirmedByPlayer = new Map();

function clearExpiredConfirmed() {
  const now = Date.now();

  for (const [playerId, entry] of confirmedByPlayer.entries()) {
    if (!entry || entry.expiresAt <= now) {
      confirmedByPlayer.delete(playerId);
    }
  }
}

function getConfirmed(playerId) {
  clearExpiredConfirmed();

  const entry = confirmedByPlayer.get(playerId);
  if (!entry) return null;

  if (entry.expiresAt <= Date.now()) {
    confirmedByPlayer.delete(playerId);
    return null;
  }

  return entry;
}

function storeConfirmed({ matchId, player, opponent, formatType, winsRequired }) {
  confirmedByPlayer.set(player.playerId, {
    matchId,
    formatType,
    winsRequired,
    opponent: {
      playerId: opponent.playerId,
      username: opponent.username,
      rating: opponent.rating,
    },
    expiresAt: Date.now() + CONFIRMED_STATUS_TTL_MS,
  });
}

/**
 * Normalize wins_required according to format.
 *
 * - bestOf3  -> 2
 * - bestOf5  -> 3
 * - bestOf7  -> 4
 * - bestOf9  -> 5
 * - custom   -> 2 through 99
 * - unlimited-> 0
 */
function normalizeWinsRequired(formatType, rawWinsRequired) {
  if (formatType === 'unlimited') {
    return { ok: true, winsRequired: 0 };
  }

  if (formatType === 'custom') {
    const value = Number(rawWinsRequired);

    if (!Number.isInteger(value) || value < 2 || value > 99) {
      return { ok: false, error: 'INVALID VALUE' };
    }

    return { ok: true, winsRequired: value };
  }

  if (Object.prototype.hasOwnProperty.call(STANDARD_WINS_REQUIRED, formatType)) {
    return { ok: true, winsRequired: STANDARD_WINS_REQUIRED[formatType] };
  }

  return { ok: false, error: 'Invalid format type.' };
}

function createQuickMatchRouter(pool) {
  const router = Router();

  // All quick-match routes require authentication.
  router.use(requireAuth);

  /**
   * When both players confirm READY, store the confirmed match state briefly
   * so either client can poll /quick-match/status and proceed.
   */
  readyUpManager.onConfirmed((matchId, playerA, playerB, formatType, winsRequired) => {
    storeConfirmed({
      matchId,
      player: playerA,
      opponent: playerB,
      formatType,
      winsRequired,
    });

    storeConfirmed({
      matchId,
      player: playerB,
      opponent: playerA,
      formatType,
      winsRequired,
    });
  });

  // ── POST /quick-match/join ────────────────────────────────────────────
  router.post('/join', async (req, res) => {
    try {
      const { playerId, username } = req.player;
      const { formatType, winsRequired } = req.body;

      if (!formatType) {
        return res.status(400).json({ error: 'formatType is required.' });
      }

      if (!VALID_FORMATS.includes(formatType)) {
        return res.status(400).json({ error: 'Invalid format type.' });
      }

      const normalized = normalizeWinsRequired(formatType, winsRequired);
      if (!normalized.ok) {
        return res.status(400).json({ error: normalized.error });
      }

      const normalizedWinsRequired = normalized.winsRequired;

      // Fetch player rating.
      const ratingResult = await pool.query(
        'SELECT rating FROM account WHERE player_id = $1',
        [playerId]
      );

      const rating =
        ratingResult.rows.length > 0 ? ratingResult.rows[0].rating : 1000;

      /**
       * Clean up stale state before joining:
       * - remove old queue entries
       * - cancel old pending ready-up entries
       * - remove old confirmed polling entries
       */
      matchQueue.removeByPlayerId(playerId);

      const existingPending = readyUpManager.getPendingMatch(playerId);
      if (existingPending) {
        readyUpManager.cancelPlayer(existingPending.matchId, playerId);
      }

      const existingConfirmed = getConfirmed(playerId);
      if (existingConfirmed) {
        confirmedByPlayer.delete(playerId);
      }

      // Try to match.
      const match = matchQueue.join({
        playerId,
        username,
        rating,
        formatType,
        winsRequired: normalizedWinsRequired,
        mode: 'casual',
      });

      if (match) {
        const { player1, player2 } = match;

        const matchResult = await pool.query(
          `INSERT INTO match (mode, format_type, wins_required, player_a_id, player_b_id)
           VALUES ('casual', $1, $2, $3, $4)
           RETURNING match_id`,
          [
            formatType,
            normalizedWinsRequired,
            player1.playerId,
            player2.playerId,
          ]
        );

        const matchId = matchResult.rows[0].match_id;

        readyUpManager.startReadyUp({
          matchId,
          playerA: {
            playerId: player1.playerId,
            username: player1.username,
            rating: player1.rating,
          },
          playerB: {
            playerId: player2.playerId,
            username: player2.username,
            rating: player2.rating,
          },
          formatType,
          winsRequired: normalizedWinsRequired,
        });

        /**
         * Return the actual opponent.
         *
         * The previous implementation returned player2 unconditionally,
         * which caused the joining player to see themselves as opponent.
         */
        const opponent =
          player1.playerId === playerId ? player2 : player1;

        return res.json({
          status: 'matched',
          matchId,
          formatType,
          winsRequired: normalizedWinsRequired,
          rating,
          opponent: {
            playerId: opponent.playerId,
            username: opponent.username,
            rating: opponent.rating,
          },
        });
      }

      // Enqueued — waiting for opponent.
      return res.json({
        status: 'searching',
        formatType,
        winsRequired: normalizedWinsRequired,
        rating,
        message: 'SEARCHING FOR OPPONENT...',
      });
    } catch (err) {
      console.error('Quick match join error:', err);
      return res.status(500).json({ error: 'Internal server error.' });
    }
  });

  // ── GET /quick-match/status ───────────────────────────────────────────
  /**
   * Polling states:
   *
   * searching -> still in queue
   * ready_up  -> opponent found, waiting for READY confirmation
   * confirmed -> both players READY, client may proceed to match
   * idle      -> no active Quick Match state
   */
  router.get('/status', (req, res) => {
    const { playerId } = req.player;

    clearExpiredConfirmed();

    // 1. Still searching in queue.
    const entry = matchQueue.getStatus(playerId);
    if (entry) {
      return res.json({
        status: 'searching',
        formatType: entry.formatType,
        winsRequired: entry.winsRequired,
        rating: entry.rating,
        message: 'SEARCHING FOR OPPONENT...',
      });
    }

    // 2. Both players confirmed READY.
    const confirmed = getConfirmed(playerId);
    if (confirmed) {
      return res.json({
        status: 'confirmed',
        matchId: confirmed.matchId,
        formatType: confirmed.formatType,
        winsRequired: confirmed.winsRequired,
        opponentName: confirmed.opponent.username,
        opponent: {
          playerId: confirmed.opponent.playerId,
          username: confirmed.opponent.username,
          rating: confirmed.opponent.rating,
        },
      });
    }

    // 3. Matched, but READY confirmation is still pending.
    const pending = readyUpManager.getPendingMatch(playerId);
    if (pending) {
      const opponent =
        pending.playerA.playerId === playerId
          ? pending.playerB
          : pending.playerA;

      return res.json({
        status: 'ready_up',
        matchId: pending.matchId,
        formatType: pending.formatType,
        winsRequired: pending.winsRequired,
        opponentName: opponent.username,
        opponent: {
          playerId: opponent.playerId,
          username: opponent.username,
          rating: opponent.rating,
        },
      });
    }

    // 4. No active Quick Match state.
    return res.json({ status: 'idle' });
  });

  // ── DELETE /quick-match/cancel ────────────────────────────────────────
  router.delete('/cancel', (req, res) => {
    const { playerId } = req.player;

    const removedFromQueue = matchQueue.cancel(playerId);

    const pending = readyUpManager.getPendingMatch(playerId);
    let cancelledPending = false;

    if (pending) {
      cancelledPending = readyUpManager.cancelPlayer(pending.matchId, playerId);
    }

    clearExpiredConfirmed();

    const confirmed = getConfirmed(playerId);
    if (confirmed) {
      confirmedByPlayer.delete(playerId);
    }

    return res.json({
      message:
        removedFromQueue || cancelledPending
          ? 'Quick match cancelled.'
          : 'No active quick match entry found.',
    });
  });

  // ── POST /quick-match/ready ───────────────────────────────────────────
  router.post('/ready', async (req, res) => {
    try {
      const { playerId } = req.player;
      const { matchId } = req.body;

      const requestedMatchId = Number(matchId);

      if (!matchId || !Number.isInteger(requestedMatchId)) {
        return res.status(400).json({ error: 'matchId is required.' });
      }

      clearExpiredConfirmed();

      // Already confirmed through polling state.
      const confirmed = getConfirmed(playerId);
      if (confirmed && confirmed.matchId === requestedMatchId) {
        return res.json({
          status: 'confirmed',
          matchId: confirmed.matchId,
          formatType: confirmed.formatType,
          winsRequired: confirmed.winsRequired,
          opponentName: confirmed.opponent.username,
          opponent: {
            playerId: confirmed.opponent.playerId,
            username: confirmed.opponent.username,
            rating: confirmed.opponent.rating,
          },
          message: 'Both players ready. Match starting!',
        });
      }

      // Verify the player is part of this pending ready-up.
      const pending = readyUpManager.getPendingMatch(playerId);

      if (!pending || pending.matchId !== requestedMatchId) {
        // Fallback: check whether the match already exists in DB.
        const matchResult = await pool.query(
          'SELECT player_a_id, player_b_id FROM match WHERE match_id = $1',
          [requestedMatchId]
        );

        if (matchResult.rows.length === 0) {
          return res.status(404).json({ error: 'Match not found.' });
        }

        const match = matchResult.rows[0];

        if (
          match.player_a_id !== playerId &&
          match.player_b_id !== playerId
        ) {
          return res
            .status(403)
            .json({ error: 'You are not part of this match.' });
        }

        return res.json({
          status: 'already_confirmed',
          matchId: requestedMatchId,
        });
      }

      const result = readyUpManager.playerReady(requestedMatchId, playerId);

      if (
        result.status === 'not_found' ||
        result.status === 'not_participant'
      ) {
        return res.status(400).json({ error: 'Invalid ready-up request.' });
      }

      if (result.status === 'confirmed') {
        const confirmedAfter = getConfirmed(playerId);

        return res.json({
          status: 'confirmed',
          matchId: requestedMatchId,
          formatType: confirmedAfter?.formatType,
          winsRequired: confirmedAfter?.winsRequired,
          opponentName: confirmedAfter?.opponent?.username,
          opponent: confirmedAfter?.opponent,
          message: 'Both players ready. Match starting!',
        });
      }

      // Still waiting for the other player.
      const opponent = readyUpManager.getOpponent(requestedMatchId, playerId);

      return res.json({
        status: 'waiting',
        matchId: requestedMatchId,
        opponentName: opponent?.username,
        opponent: opponent
          ? {
              playerId: opponent.playerId,
              username: opponent.username,
              rating: opponent.rating,
            }
          : null,
      });
    } catch (err) {
      console.error('Quick match ready error:', err);
      return res.status(500).json({ error: 'Internal server error.' });
    }
  });

  return router;
}

module.exports = { createQuickMatchRouter };