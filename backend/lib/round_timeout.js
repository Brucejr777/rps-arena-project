/**
 * Round timeout manager (T100).
 *
 * When a round starts (first move arrives), starts a 10-second timer.
 * If a player hasn't submitted after 10 seconds:
 *   - Server assigns a random move (rock/paper/scissors)
 *   - Server marks that player's auto flag as true
 *   - Round resolves normally
 */

const ROUND_TIMEOUT_MS = 10_000;
const VALID_MOVES = ['rock', 'paper', 'scissors'];

class RoundTimeoutManager {
  constructor() {
    /** @type {Map<string, NodeJS.Timeout>} key: "{matchId}:{round}" → timer */
    this._timers = new Map();
    /** @type {Map<string, {matchId: number, roundNumber: number, playerId: number, isPlayerA: boolean}>} */
    this._pending = new Map();
    /** callback when timeout fires */
    this._onTimeout = null;
  }

  onTimeout(callback) {
    this._onTimeout = callback;
  }

  _key(matchId, roundNumber) {
    return `${matchId}:${roundNumber}`;
  }

  /**
   * Start the 10-second timer for a round.
   * Call this when the first move of a round arrives.
   */
  startTimer(matchId, roundNumber, waitingPlayerId, isPlayerA) {
    const key = this._key(matchId, roundNumber);

    // Don't start if already running
    if (this._timers.has(key)) return;

    this._pending.set(key, { matchId, roundNumber, playerId: waitingPlayerId, isPlayerA });

    const timer = setTimeout(() => {
      this._fireTimeout(key);
    }, ROUND_TIMEOUT_MS);

    this._timers.set(key, timer);
  }

  /**
   * Cancel the timer for a round (both players submitted before timeout).
   */
  cancelTimer(matchId, roundNumber) {
    const key = this._key(matchId, roundNumber);
    const timer = this._timers.get(key);
    if (timer) {
      clearTimeout(timer);
      this._timers.delete(key);
      this._pending.delete(key);
    }
  }

  /**
   * Generate a random move for a timed-out player.
   */
  static randomMove() {
    return VALID_MOVES[Math.floor(Math.random() * VALID_MOVES.length)];
  }

  _fireTimeout(key) {
    const pending = this._pending.get(key);
    this._timers.delete(key);
    this._pending.delete(key);

    if (pending && this._onTimeout) {
      const autoMove = RoundTimeoutManager.randomMove();
      this._onTimeout({
        matchId: pending.matchId,
        roundNumber: pending.roundNumber,
        playerId: pending.playerId,
        isPlayerA: pending.isPlayerA,
        autoMove,
      });
    }
  }

  /**
   * Check if a timer is active for a given round.
   */
  hasActiveTimer(matchId, roundNumber) {
    return this._timers.has(this._key(matchId, roundNumber));
  }
}

const roundTimeoutManager = new RoundTimeoutManager();

module.exports = { RoundTimeoutManager, roundTimeoutManager, ROUND_TIMEOUT_MS };
