const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { MatchQueue, queueKey } = require('../lib/match_queue');

describe('queueKey', () => {
  it('returns mode:format:winsRequired for standard formats', () => {
    assert.strictEqual(queueKey('casual', 'bestOf3'), 'casual:bestOf3:0');
  });

  it('includes winsRequired for custom', () => {
    assert.strictEqual(queueKey('casual', 'custom', 5), 'casual:custom:5');
  });

  it('uses 0 for unlimited', () => {
    assert.strictEqual(queueKey('casual', 'unlimited'), 'casual:unlimited:0');
  });

  it('separates ranked from casual', () => {
    assert.notStrictEqual(queueKey('ranked', 'bestOf3'), queueKey('casual', 'bestOf3'));
  });
});

describe('MatchQueue', () => {
  /** @type {MatchQueue} */
  let q;

  beforeEach(() => {
    q = new MatchQueue();
  });

  it('returns null when no opponent is waiting', () => {
    const result = q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'bestOf3' });
    assert.strictEqual(result, null);
  });

  it('pairs two players in the same format queue', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'bestOf3' });
    const result = q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'bestOf3' });

    assert.notStrictEqual(result, null);
    assert.strictEqual(result.player1.playerId, 1); // longest waiting first
    assert.strictEqual(result.player2.playerId, 2);
  });

  it('keeps players in separate queues for different formats', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'bestOf3' });
    const result = q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'bestOf5' });

    assert.strictEqual(result, null); // different format, no match
  });

  it('separates CUSTOM queues by wins_required', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'custom', winsRequired: 3 });
    const result = q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'custom', winsRequired: 5 });

    assert.strictEqual(result, null); // different wins_required, no match
  });

  it('matches CUSTOM players with same wins_required', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'custom', winsRequired: 7 });
    const result = q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'custom', winsRequired: 7 });

    assert.notStrictEqual(result, null);
    assert.strictEqual(result.player1.playerId, 1);
  });

  it('UNLIMITED uses wins_required 0', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'unlimited' });
    const result = q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'unlimited' });

    assert.notStrictEqual(result, null);
  });

  it('cancel removes a player from the queue', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'bestOf3' });
    const removed = q.cancel(1);
    assert.strictEqual(removed, true);

    // Queue is now empty, next join returns null
    const result = q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'bestOf3' });
    assert.strictEqual(result, null);
  });

  it('cancel returns false for unknown player', () => {
    assert.strictEqual(q.cancel(999), false);
  });

  it('getStatus returns the queue entry', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'bestOf3' });
    const status = q.getStatus(1);
    assert.notStrictEqual(status, null);
    assert.strictEqual(status.username, 'Alice');
    assert.strictEqual(status.formatType, 'bestOf3');
  });

  it('getStatus returns null for unknown player', () => {
    assert.strictEqual(q.getStatus(999), null);
  });

  it('getQueueLength returns correct count', () => {
    q.join({ playerId: 1, username: 'Alice', rating: 1000, formatType: 'bestOf3' });
    q.join({ playerId: 2, username: 'Bob', rating: 1100, formatType: 'bestOf5' });
    q.join({ playerId: 3, username: 'Carol', rating: 900, formatType: 'bestOf3' }); // matches with 1

    assert.strictEqual(q.getQueueLength('bestOf3'), 0); // 1 joined, 3 matched → 0 left
    assert.strictEqual(q.getQueueLength('bestOf5'), 1); // 2 still waiting
  });

  it('pairs longest-waiting player first (FIFO)', () => {
    q.join({ playerId: 1, username: 'First', rating: 1000, formatType: 'bestOf3' });
    q.join({ playerId: 2, username: 'Second', rating: 1100, formatType: 'bestOf3' });
    q.join({ playerId: 3, username: 'Third', rating: 1200, formatType: 'bestOf3' });

    // First joined, so they should be matched with Second
    // Third is now alone in the queue
    const status = q.getStatus(3);
    assert.notStrictEqual(status, null);
    assert.strictEqual(status.username, 'Third');
  });
});
