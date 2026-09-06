/**
 * DisconnectionManager (T104)
 *
 * Tracks disconnected players in active matches.
 * When a player disconnects, a 30-second reconnect window starts.
 * - If the player reconnects within 30s → cancel timer, continue match
 * - If the timer expires → assign loss to disconnected player, opponent wins
 */

class DisconnectionManager {
  constructor() {
    // Map<matchId, Map<playerId, { timer, isPlayerA }>>
    this.disconnections = new Map();
    // Map<matchId, Function> — per-match timeout callback
    this._onTimeoutCallbacks = new Map();
    this.RECONNECT_WINDOW_MS = 30_000; // 30 seconds
  }

  /**
   * Register a disconnect for a player in a match.
   * @param {number} matchId
   * @param {number} playerId
   * @param {boolean} isPlayerA
   * @param {Function} onTimeout - Called with { matchId, playerId, isPlayerA } when 30s expires
   */
  startDisconnect(matchId, playerId, isPlayerA, onTimeout) {
    if (!this.disconnections.has(matchId)) {
      this.disconnections.set(matchId, new Map());
    }

    const matchDisconnections = this.disconnections.get(matchId);

    // Clear existing timer if any
    if (matchDisconnections.has(playerId)) {
      clearTimeout(matchDisconnections.get(playerId).timer);
    }

    const timer = setTimeout(() => {
      this.onDisconnectTimeout(matchId, playerId, isPlayerA);
      matchDisconnections.delete(playerId);
      if (matchDisconnections.size === 0) {
        this.disconnections.delete(matchId);
      }
    }, this.RECONNECT_WINDOW_MS);

    matchDisconnections.set(playerId, { timer, isPlayerA, startTime: Date.now() });

    if (onTimeout) {
      this._onTimeoutCallbacks.set(matchId, onTimeout);
    }
  }

  /**
   * Handle disconnect timeout — assign loss to disconnected player.
   */
  onDisconnectTimeout(matchId, playerId, isPlayerA) {
    const callback = this._onTimeoutCallbacks.get(matchId);
    if (callback) {
      this._onTimeoutCallbacks.delete(matchId);
      callback({ matchId, playerId, isPlayerA });
    }
  }

  /**
   * Cancel disconnect timer for a player (they reconnected).
   * @returns {boolean} true if a timer was cancelled
   */
  cancelDisconnect(matchId, playerId) {
    const matchDisconnections = this.disconnections.get(matchId);
    if (!matchDisconnections || !matchDisconnections.has(playerId)) {
      return false;
    }

    const entry = matchDisconnections.get(playerId);
    clearTimeout(entry.timer);
    matchDisconnections.delete(playerId);

    if (matchDisconnections.size === 0) {
      this.disconnections.delete(matchId);
    }

    return true;
  }

  /**
   * Check if a player is currently in a disconnect window.
   */
  isDisconnected(matchId, playerId) {
    const matchDisconnections = this.disconnections.get(matchId);
    return matchDisconnections ? matchDisconnections.has(playerId) : false;
  }

  /**
   * Get remaining time in ms for a disconnect window.
   */
  getRemainingTime(matchId, playerId) {
    const matchDisconnections = this.disconnections.get(matchId);
    if (!matchDisconnections || !matchDisconnections.has(playerId)) {
      return 0;
    }

    const entry = matchDisconnections.get(playerId);
    const elapsed = Date.now() - entry.startTime;
    return Math.max(0, this.RECONNECT_WINDOW_MS - elapsed);
  }

  /**
   * Clean up all timers (for testing).
   */
  clearAll() {
    for (const [, matchDisconnections] of this.disconnections) {
      for (const [, entry] of matchDisconnections) {
        clearTimeout(entry.timer);
      }
    }
    this.disconnections.clear();
    this._onTimeoutCallbacks.clear();
  }
}

// Singleton instance
const disconnectManager = new DisconnectionManager();

module.exports = { DisconnectionManager, disconnectManager };
