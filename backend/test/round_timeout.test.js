const { describe, it, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { RoundTimeoutManager, ROUND_TIMEOUT_MS } = require('../lib/round_timeout');

describe('RoundTimeoutManager (T100)', () => {
  /** @type {RoundTimeoutManager} */
  let manager;
  let timeoutCalls;

  afterEach(() => {
    // Clean up any lingering timers
    if (manager) {
      manager.cancelTimer(1, 1);
      manager.cancelTimer(2, 1);
    }
  });

  it('fires callback after 10 seconds with random move', (_, done) => {
    manager = new RoundTimeoutManager();
    timeoutCalls = [];

    manager.onTimeout((data) => {
      timeoutCalls.push(data);
      assert.strictEqual(data.matchId, 1);
      assert.strictEqual(data.roundNumber, 1);
      assert.strictEqual(data.playerId, 2);
      assert.strictEqual(data.isPlayerA, false);
      assert.ok(['rock', 'paper', 'scissors'].includes(data.autoMove));
      done();
    });

    manager.startTimer(1, 1, 2, false);
  });

  it('cancelTimer prevents timeout from firing', (_, done) => {
    manager = new RoundTimeoutManager();
    timeoutCalls = [];

    manager.onTimeout((data) => {
      timeoutCalls.push(data);
    });

    manager.startTimer(1, 1, 2, false);
    manager.cancelTimer(1, 1);

    setTimeout(() => {
      assert.strictEqual(timeoutCalls.length, 0);
      done();
    }, ROUND_TIMEOUT_MS + 200);
  });

  it('does not start duplicate timer for same round', (_, done) => {
    manager = new RoundTimeoutManager();
    let callCount = 0;

    manager.onTimeout(() => { callCount++; });

    manager.startTimer(1, 1, 2, false);
    manager.startTimer(1, 1, 3, true); // duplicate — should be ignored

    setTimeout(() => {
      assert.strictEqual(callCount, 1); // only one timeout
      done();
    }, ROUND_TIMEOUT_MS + 200);
  });

  it('different rounds have independent timers', (_, done) => {
    manager = new RoundTimeoutManager();
    const calls = [];

    manager.onTimeout((data) => { calls.push(data.roundNumber); });

    manager.startTimer(1, 1, 2, false);
    manager.startTimer(1, 2, 3, true);

    // Cancel round 1 — round 2 should still fire
    manager.cancelTimer(1, 1);

    setTimeout(() => {
      assert.deepStrictEqual(calls, [2]);
      done();
    }, ROUND_TIMEOUT_MS + 200);
  });

  it('hasActiveTimer returns correct state', () => {
    manager = new RoundTimeoutManager();
    manager.onTimeout(() => {});

    assert.strictEqual(manager.hasActiveTimer(1, 1), false);
    manager.startTimer(1, 1, 2, false);
    assert.strictEqual(manager.hasActiveTimer(1, 1), true);
    manager.cancelTimer(1, 1);
    assert.strictEqual(manager.hasActiveTimer(1, 1), false);
  });

  it('randomMove returns a valid move', () => {
    for (let i = 0; i < 100; i++) {
      const move = RoundTimeoutManager.randomMove();
      assert.ok(['rock', 'paper', 'scissors'].includes(move));
    }
  });
});
