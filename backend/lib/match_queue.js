/**
 * In-memory Quick Match queue (T87).
 *
 * Queue rules:
 *   - Separate queue per format_type.
 *   - CUSTOM queue also separates by wins_required.
 *   - UNLIMITED queue uses wins_required 0.
 *   - Longest-waiting player pairs with the next player in same queue.
 */

/**
 * Generate the queue key that groups compatible players.
 * @param {string} formatType  e.g. 'bestOf3', 'custom', 'unlimited'
 * @param {number} winsRequired  only relevant for 'custom'
 */
function queueKey(mode, formatType, winsRequired = 0) {
  return `${mode}:${formatType}:${winsRequired}`;
}

class MatchQueue {
  constructor() {
    /** @type {Map<string, Array<{playerId: number, username: string, rating: number, joinedAt: number, formatType: string, winsRequired: number}>>} */
    this._queues = new Map();
  }

  /**
   * Add a player to the queue.
   * Returns the matched opponent if one was waiting, or null.
   */
  join({ playerId, username, rating, formatType, winsRequired = 0, mode = 'casual' }) {
    const key = queueKey(mode, formatType, winsRequired);

    if (!this._queues.has(key)) {
      this._queues.set(key, []);
    }

    const queue = this._queues.get(key);

    // Check if a match can be made (longest-waiting player first)
    if (queue.length > 0) {
      const opponent = queue.shift(); // longest waiting
      return { player1: opponent, player2: { playerId, username, rating, joinedAt: Date.now(), formatType, winsRequired } };
    }

    // No opponent yet — enqueue this player
    queue.push({ playerId, username, rating, joinedAt: Date.now(), formatType, winsRequired });
    return null;
  }

  /**
   * Remove a player from the queue.
   * Returns true if the player was found and removed.
   */
  cancel(playerId) {
    return this.removeByPlayerId(playerId);
  }

  /**
   * Remove a player from every format queue (idempotent).
   * Returns true if the player was found in any queue.
   */
  removeByPlayerId(playerId) {
    for (const [key, queue] of this._queues) {
      const index = queue.findIndex((e) => e.playerId === playerId);
      if (index !== -1) {
        queue.splice(index, 1);
        if (queue.length === 0) {
          this._queues.delete(key);
        }
        return true;
      }
    }
    return false;
  }

  /**
   * Get the current queue entry for a player (for displaying status).
   * Returns the entry or null.
   */
  getStatus(playerId) {
    for (const queue of this._queues.values()) {
      const entry = queue.find((e) => e.playerId === playerId);
      if (entry) return entry;
    }
    return null;
  }

  /**
   * Get the queue length for a given format.
   */
  getQueueLength(formatType, winsRequired = 0, mode = 'casual') {
    const key = queueKey(mode, formatType, winsRequired);
    const queue = this._queues.get(key);
    return queue ? queue.length : 0;
  }
}

// Singleton instance
const matchQueue = new MatchQueue();

module.exports = { MatchQueue, matchQueue, queueKey };
