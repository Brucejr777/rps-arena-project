const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { DisconnectionManager } = require('../lib/disconnect_manager');

describe('DisconnectionManager (T104)', () => {
  let dm;

  beforeEach(() => {
    dm = new DisconnectionManager();
    // Speed up tests: use 200ms instead of 30s
    dm.RECONNECT_WINDOW_MS = 200;
  });

  afterEach(() => {
    dm.clearAll();
  });

  it('startDisconnect registers a disconnect', () => {
    dm.startDisconnect(1, 10, true, () => {});
    assert.equal(dm.isDisconnected(1, 10), true);
  });

  it('cancelDisconnect removes the disconnect', () => {
    dm.startDisconnect(1, 10, true, () => {});
    const cancelled = dm.cancelDisconnect(1, 10);
    assert.equal(cancelled, true);
    assert.equal(dm.isDisconnected(1, 10), false);
  });

  it('cancelDisconnect returns false if not disconnected', () => {
    const cancelled = dm.cancelDisconnect(1, 99);
    assert.equal(cancelled, false);
  });

  it('onTimeout callback fires after reconnect window expires', async () => {
    let timeoutFired = false;
    let timeoutData = null;

    dm.startDisconnect(1, 10, true, (data) => {
      timeoutFired = true;
      timeoutData = data;
    });

    await new Promise(r => setTimeout(r, 300));

    assert.equal(timeoutFired, true);
    assert.equal(timeoutData.matchId, 1);
    assert.equal(timeoutData.playerId, 10);
    assert.equal(timeoutData.isPlayerA, true);
  });

  it('cancelDisconnect prevents timeout from firing', async () => {
    let timeoutFired = false;

    dm.startDisconnect(1, 10, true, () => {
      timeoutFired = true;
    });

    await new Promise(r => setTimeout(r, 100));
    dm.cancelDisconnect(1, 10);
    await new Promise(r => setTimeout(r, 200));

    assert.equal(timeoutFired, false);
  });

  it('multiple players in same match tracked independently', async () => {
    let timeoutA = false;
    let timeoutB = false;

    dm.startDisconnect(1, 10, true, () => { timeoutA = true; });
    dm.startDisconnect(1, 20, false, () => { timeoutB = true; });

    // Cancel player A before timeout
    await new Promise(r => setTimeout(r, 100));
    dm.cancelDisconnect(1, 10);

    // Wait for player B timeout
    await new Promise(r => setTimeout(r, 200));

    assert.equal(timeoutA, false); // A was cancelled
    assert.equal(timeoutB, true);  // B timed out
  });

  it('different matches tracked independently', async () => {
    let timeoutM1 = false;
    let timeoutM2 = false;

    dm.startDisconnect(1, 10, true, () => { timeoutM1 = true; });
    dm.startDisconnect(2, 10, false, () => { timeoutM2 = true; });

    // Cancel match 1 disconnect
    await new Promise(r => setTimeout(r, 100));
    dm.cancelDisconnect(1, 10);

    await new Promise(r => setTimeout(r, 200));

    assert.equal(timeoutM1, false); // Match 1 cancelled
    assert.equal(timeoutM2, true);  // Match 2 timed out
  });

  it('getRemainingTime returns 0 for unknown disconnect', () => {
    assert.equal(dm.getRemainingTime(1, 99), 0);
  });

  it('getRemainingTime returns positive value for active disconnect', () => {
    dm.startDisconnect(1, 10, true, () => {});
    const remaining = dm.getRemainingTime(1, 10);
    assert.ok(remaining > 0);
    assert.ok(remaining <= 200);
  });

  it('clearAll removes all disconnects', () => {
    dm.startDisconnect(1, 10, true, () => {});
    dm.startDisconnect(2, 20, false, () => {});

    dm.clearAll();

    assert.equal(dm.isDisconnected(1, 10), false);
    assert.equal(dm.isDisconnected(2, 20), false);
  });

  it('replacing disconnect with new timer (same player)', async () => {
    let callCount = 0;

    // Start first disconnect
    dm.startDisconnect(1, 10, true, () => { callCount++; });

    // Wait partway, then restart for same player (clears old timer)
    await new Promise(r => setTimeout(r, 100));
    dm.startDisconnect(1, 10, true, () => { callCount++; });

    // Wait for second timer to fire (needs full 200ms from restart)
    await new Promise(r => setTimeout(r, 250));

    // Only the second timer should fire (first was cleared)
    assert.equal(callCount, 1);
  });
});
