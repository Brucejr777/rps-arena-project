const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { ReadyUpManager, READY_TIMEOUT_MS } = require('../lib/ready_up_manager');

describe('ReadyUpManager', () => {
  /** @type {ReadyUpManager} */
  let manager;
  let confirmedCalls;
  let cancelledCalls;

  beforeEach(() => {
    manager = new ReadyUpManager();
    confirmedCalls = [];
    cancelledCalls = [];
    manager.onConfirmed((matchId, pA, pB, fmt, wins) => {
      confirmedCalls.push({ matchId, playerA: pA, playerB: pB, formatType: fmt, winsRequired: wins });
    });
    manager.onCancelled((matchId) => {
      cancelledCalls.push(matchId);
    });
  });

  afterEach(() => {
    // Clean up any lingering timers
    const pending = manager.getPendingMatch(1) || manager.getPendingMatch(2) || manager.getPendingMatch(3);
    if (pending) clearTimeout(pending.timer);
  });

  it('records first player as waiting', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    const result = manager.playerReady(1, 1);
    assert.strictEqual(result.status, 'waiting');
  });

  it('confirms match when both players are ready', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    manager.playerReady(1, 1);
    const result = manager.playerReady(1, 2);

    assert.strictEqual(result.status, 'confirmed');
    assert.strictEqual(confirmedCalls.length, 1);
    assert.strictEqual(confirmedCalls[0].matchId, 1);
    assert.strictEqual(confirmedCalls[0].playerA.username, 'Alice');
    assert.strictEqual(confirmedCalls[0].playerB.username, 'Bob');
  });

  it('cancels match on 15s timeout', (_, done) => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf5',
      winsRequired: 3,
    });

    // Only player 1 confirms — player 2 doesn't
    manager.playerReady(1, 1);

    setTimeout(() => {
      assert.strictEqual(cancelledCalls.length, 1);
      assert.strictEqual(cancelledCalls[0], 1);
      assert.strictEqual(confirmedCalls.length, 0);
      done();
    }, READY_TIMEOUT_MS + 100);
  });

  it('returns not_found for unknown matchId', () => {
    const result = manager.playerReady(999, 1);
    assert.strictEqual(result.status, 'not_found');
  });

  it('returns not_participant for player not in match', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    const result = manager.playerReady(1, 999);
    assert.strictEqual(result.status, 'not_participant');
  });

  it('cancelPlayer cancels the match', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    const removed = manager.cancelPlayer(1, 2);
    assert.strictEqual(removed, true);
    assert.strictEqual(cancelledCalls.length, 1);
  });

  it('getPendingMatch returns match for player in pending', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    const pending = manager.getPendingMatch(1);
    assert.notStrictEqual(pending, null);
    assert.strictEqual(pending.matchId, 1);

    const pending2 = manager.getPendingMatch(2);
    assert.notStrictEqual(pending2, null);
    assert.strictEqual(pending2.matchId, 1);
  });

  it('getOpponent returns the other player', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    const opp = manager.getOpponent(1, 1);
    assert.strictEqual(opp.username, 'Bob');

    const opp2 = manager.getOpponent(1, 2);
    assert.strictEqual(opp2.username, 'Alice');
  });

  it('same player ready twice is idempotent (no double-confirm)', () => {
    manager.startReadyUp({
      matchId: 1,
      playerA: { playerId: 1, username: 'Alice', rating: 1000 },
      playerB: { playerId: 2, username: 'Bob', rating: 1100 },
      formatType: 'bestOf3',
      winsRequired: 2,
    });

    manager.playerReady(1, 1);
    manager.playerReady(1, 1); // duplicate
    assert.strictEqual(confirmedCalls.length, 0); // still waiting
  });
});
