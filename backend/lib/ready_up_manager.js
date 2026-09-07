/**
 * Ready-up manager for Quick Match (T89).
 *
 * After two players are matched:
 *   1. Both players have 15 seconds to confirm readiness.
 *   2. If both confirm → match proceeds.
 *   3. If either fails to confirm → match cancelled.
 */

const READY_TIMEOUT_MS = 15_000; // T89: ready period 15 seconds

/**
 * @typedef {{ matchId: number, playerA: {playerId, username, rating}, playerB: {playerId, username, rating}, readyPlayers: Set<number>, timer: NodeJS.Timeout, formatType: string, winsRequired: number }} PendingMatch
 */

class ReadyUpManager {
  constructor() {
    /** @type {Map<number, PendingMatch>} matchId → pending match */
    this._pending = new Map();
    /** callback when match is confirmed: (matchId, playerA, playerB, formatType, winsRequired) => void */
    this._onConfirmed = null;
    /** callback when match is cancelled: (matchId) => void */
    this._onCancelled = null;
  }

  /** Register callbacks for match lifecycle events. */
  onConfirmed(callback) {
    this._onConfirmed = callback;
  }

  onCancelled(callback) {
    this._onCancelled = callback;
  }

  /**
   * Start the ready-up countdown for a newly matched pair.
   */
  startReadyUp({ matchId, playerA, playerB, formatType, winsRequired }) {
    const timer = setTimeout(() => {
      // Timeout — cancel the match
      this._cancelMatch(matchId);
    }, READY_TIMEOUT_MS);

    this._pending.set(matchId, {
      matchId,
      playerA,
      playerB,
      readyPlayers: new Set(),
      timer,
      formatType,
      winsRequired,
    });
  }

  /**
   * Mark a player as ready for a given match.
   * Returns { status: 'waiting' | 'confirmed', matchId }.
   */
  playerReady(matchId, playerId) {
    const pending = this._pending.get(matchId);
    if (!pending) {
      return { status: 'not_found' };
    }

    // Verify the player is part of this match
    if (pending.playerA.playerId !== playerId && pending.playerB.playerId !== playerId) {
      return { status: 'not_participant' };
    }

    pending.readyPlayers.add(playerId);

    if (pending.readyPlayers.size >= 2) {
      // Both players ready — confirm the match
      this._confirmMatch(matchId);
      return { status: 'confirmed', matchId };
    }

    return { status: 'waiting', matchId };
  }

  /**
   * Cancel a player's pending match (e.g. they left).
   */
  cancelPlayer(matchId, playerId) {
    const pending = this._pending.get(matchId);
    if (!pending) return false;

    if (pending.playerA.playerId !== playerId && pending.playerB.playerId !== playerId) {
      return false;
    }

    this._cancelMatch(matchId);
    return true;
  }

  /**
   * Get the pending match info for a player.
   */
  getPendingMatch(playerId) {
    for (const pending of this._pending.values()) {
      if (pending.playerA.playerId === playerId || pending.playerB.playerId === playerId) {
        return pending;
      }
    }
    return null;
  }

  /**
   * Get opponent info for a player in a pending match.
   */
  getOpponent(matchId, playerId) {
    const pending = this._pending.get(matchId);
    if (!pending) return null;
    return pending.playerA.playerId === playerId ? pending.playerB : pending.playerA;
  }

  // ── Internal ──────────────────────────────────────────────────

  _confirmMatch(matchId) {
    const pending = this._pending.get(matchId);
    if (!pending) return;

    clearTimeout(pending.timer);
    this._pending.delete(matchId);

    if (this._onConfirmed) {
      this._onConfirmed(matchId, pending.playerA, pending.playerB, pending.formatType, pending.winsRequired);
    }
  }

  _cancelMatch(matchId) {
    const pending = this._pending.get(matchId);
    if (!pending) return;

    clearTimeout(pending.timer);
    this._pending.delete(matchId);

    if (this._onCancelled) {
      this._onCancelled(matchId);
    }
  }
}

const readyUpManager = new ReadyUpManager();
module.exports = { ReadyUpManager, readyUpManager, READY_TIMEOUT_MS };