const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { resolveRound } = require('../lib/resolution');

describe('resolveRound (T97) — all 9 move pairs', () => {
  // ── Draws (3 pairs) ──────────────────────────────────────────
  it('rock vs rock → draw', () => {
    assert.strictEqual(resolveRound('rock', 'rock'), 'draw');
  });

  it('paper vs paper → draw', () => {
    assert.strictEqual(resolveRound('paper', 'paper'), 'draw');
  });

  it('scissors vs scissors → draw', () => {
    assert.strictEqual(resolveRound('scissors', 'scissors'), 'draw');
  });

  // ── Player A wins (3 pairs) ──────────────────────────────────
  it('rock vs scissors → player_a_wins', () => {
    assert.strictEqual(resolveRound('rock', 'scissors'), 'player_a_wins');
  });

  it('paper vs rock → player_a_wins', () => {
    assert.strictEqual(resolveRound('paper', 'rock'), 'player_a_wins');
  });

  it('scissors vs paper → player_a_wins', () => {
    assert.strictEqual(resolveRound('scissors', 'paper'), 'player_a_wins');
  });

  // ── Player B wins (3 pairs) ──────────────────────────────────
  it('scissors vs rock → player_b_wins', () => {
    assert.strictEqual(resolveRound('scissors', 'rock'), 'player_b_wins');
  });

  it('rock vs paper → player_b_wins', () => {
    assert.strictEqual(resolveRound('rock', 'paper'), 'player_b_wins');
  });

  it('paper vs scissors → player_b_wins', () => {
    assert.strictEqual(resolveRound('paper', 'scissors'), 'player_b_wins');
  });
});
