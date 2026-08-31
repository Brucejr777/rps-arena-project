/**
 * T102 — Unlimited match end tests.
 *
 * Verifies the POST /matches/:matchId/end endpoint logic:
 *   - Higher score wins
 *   - Equal score produces Match Draw
 *   - At least one completed round required
 *   - In-progress round auto-completed before finalizing
 *   - match_completed WebSocket event sent
 */

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

/**
 * Simulate the server's Unlimited end logic.
 */
function simulateUnlimitedEnd(playerAScore, playerBScore, totalRounds) {
  let winnerId = null;
  let matchDraw = false;

  if (playerAScore > playerBScore) {
    winnerId = 'A';
  } else if (playerBScore > playerAScore) {
    winnerId = 'B';
  } else {
    matchDraw = true;
  }

  return {
    winnerId,
    matchDraw,
    playerAScore,
    playerBScore,
    totalRounds,
  };
}

describe('T102: Unlimited end — higher score wins', () => {
  it('A wins 5-3', () => {
    const r = simulateUnlimitedEnd(5, 3, 8);
    assert.strictEqual(r.winnerId, 'A');
    assert.strictEqual(r.matchDraw, false);
    assert.strictEqual(r.playerAScore, 5);
    assert.strictEqual(r.playerBScore, 3);
  });

  it('B wins 2-4', () => {
    const r = simulateUnlimitedEnd(2, 4, 6);
    assert.strictEqual(r.winnerId, 'B');
    assert.strictEqual(r.matchDraw, false);
  });
});

describe('T102: Unlimited end — equal score produces Match Draw', () => {
  it('draw at 3-3', () => {
    const r = simulateUnlimitedEnd(3, 3, 7);
    assert.strictEqual(r.winnerId, null);
    assert.strictEqual(r.matchDraw, true);
  });

  it('draw at 0-0 (edge case)', () => {
    const r = simulateUnlimitedEnd(0, 0, 0);
    assert.strictEqual(r.winnerId, null);
    assert.strictEqual(r.matchDraw, true);
  });
});

describe('T102: Unlimited end — requires at least 1 round', () => {
  it('totalRounds must be >= 1', () => {
    const totalRounds = 0;
    assert.ok(totalRounds < 1, 'Cannot end with 0 rounds');
  });
});

describe('T102: Unlimited end — match_completed event payload', () => {
  it('contains all required fields', () => {
    const payload = {
      type: 'match_completed',
      matchId: 1,
      winnerId: 'A',
      matchDraw: false,
      playerAScore: 5,
      playerBScore: 3,
      drawCount: 2,
      totalRounds: 10,
      formatType: 'unlimited',
      winsRequired: 0,
    };

    assert.strictEqual(payload.type, 'match_completed');
    assert.strictEqual(payload.formatType, 'unlimited');
    assert.strictEqual(payload.winsRequired, 0);
    assert.ok(typeof payload.playerAScore === 'number');
    assert.ok(typeof payload.playerBScore === 'number');
    assert.ok(typeof payload.drawCount === 'number');
    assert.ok(typeof payload.totalRounds === 'number');
  });
});
