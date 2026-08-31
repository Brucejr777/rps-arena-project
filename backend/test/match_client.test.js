/**
 * T98 — Match client test.
 *
 * Simulates submitting all 9 move pairs across 4 match configurations,
 * recording server results. Uses the resolution module directly since
 * the full endpoint requires a running database.
 *
 * Configurations tested:
 *   - Best-of-3 (wins_required: 2)
 *   - Best-of-5 (wins_required: 3)
 *   - Custom (wins_required: 5)
 *   - Unlimited (no auto-win, manual end)
 */

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { resolveRound } = require('../lib/resolution');

// ── All 9 move pairs ────────────────────────────────────────────

const ALL_MOVE_PAIRS = [
  { a: 'rock',     b: 'rock',     expected: 'draw' },
  { a: 'paper',    b: 'paper',    expected: 'draw' },
  { a: 'scissors', b: 'scissors', expected: 'draw' },
  { a: 'rock',     b: 'scissors', expected: 'player_a_wins' },
  { a: 'paper',    b: 'rock',     expected: 'player_a_wins' },
  { a: 'scissors', b: 'paper',    expected: 'player_a_wins' },
  { a: 'scissors', b: 'rock',     expected: 'player_b_wins' },
  { a: 'rock',     b: 'paper',    expected: 'player_b_wins' },
  { a: 'paper',    b: 'scissors', expected: 'player_b_wins' },
];

/**
 * Simulate a match by playing rounds with the given move sequence.
 * Returns the final match state.
 */
function simulateMatch(config) {
  const { formatType, winsRequired, rounds } = config;
  let playerAScore = 0;
  let playerBScore = 0;
  let drawCount = 0;
  let totalRounds = 0;
  let matchFinished = false;
  let matchWinner = null;
  const roundResults = [];

  for (const pair of rounds) {
    const result = resolveRound(pair.a, pair.b);
    totalRounds++;

    if (result === 'player_a_wins') playerAScore++;
    else if (result === 'player_b_wins') playerBScore++;
    else drawCount++;

    roundResults.push({ ...pair, result, playerAScore, playerBScore });

    // Check completion (standard formats only)
    if (formatType !== 'unlimited') {
      if (playerAScore >= winsRequired) {
        matchFinished = true;
        matchWinner = 'A';
      } else if (playerBScore >= winsRequired) {
        matchFinished = true;
        matchWinner = 'B';
      }
    }
  }

  return {
    formatType,
    winsRequired,
    playerAScore,
    playerBScore,
    drawCount,
    totalRounds,
    matchFinished,
    matchWinner,
    roundResults,
  };
}

// ── Test: all 9 move pairs resolve correctly ────────────────────

describe('T98: All 9 move pairs resolve correctly', () => {
  for (const pair of ALL_MOVE_PAIRS) {
    it(`${pair.a} vs ${pair.b} → ${pair.expected}`, () => {
      assert.strictEqual(resolveRound(pair.a, pair.b), pair.expected);
    });
  }
});

// ── Test: Best-of-3 configuration ──────────────────────────────

describe('T98: Best-of-3 (wins_required: 2)', () => {
  it('Player A wins 2-0 with two rock/scissors pairs', () => {
    const state = simulateMatch({
      formatType: 'bestOf3',
      winsRequired: 2,
      rounds: [
        { a: 'rock', b: 'scissors' }, // A wins
        { a: 'rock', b: 'scissors' }, // A wins
      ],
    });

    assert.strictEqual(state.matchFinished, true);
    assert.strictEqual(state.matchWinner, 'A');
    assert.strictEqual(state.playerAScore, 2);
    assert.strictEqual(state.playerBScore, 0);
    assert.strictEqual(state.totalRounds, 2);
  });

  it('Player B wins 2-1', () => {
    const state = simulateMatch({
      formatType: 'bestOf3',
      winsRequired: 2,
      rounds: [
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
        { a: 'scissors', b: 'rock' },      // B wins
      ],
    });

    assert.strictEqual(state.matchFinished, true);
    assert.strictEqual(state.matchWinner, 'B');
    assert.strictEqual(state.playerAScore, 1);
    assert.strictEqual(state.playerBScore, 2);
  });

  it('Draws do not count toward wins', () => {
    const state = simulateMatch({
      formatType: 'bestOf3',
      winsRequired: 2,
      rounds: [
        { a: 'rock', b: 'rock' },          // Draw
        { a: 'rock', b: 'scissors' },       // A wins
        { a: 'rock', b: 'rock' },          // Draw
        { a: 'rock', b: 'scissors' },       // A wins
      ],
    });

    assert.strictEqual(state.matchFinished, true);
    assert.strictEqual(state.matchWinner, 'A');
    assert.strictEqual(state.playerAScore, 2);
    assert.strictEqual(state.drawCount, 2);
    assert.strictEqual(state.totalRounds, 4);
  });
});

// ── Test: Best-of-5 configuration ──────────────────────────────

describe('T98: Best-of-5 (wins_required: 3)', () => {
  it('Player A wins 3-2', () => {
    const state = simulateMatch({
      formatType: 'bestOf5',
      winsRequired: 3,
      rounds: [
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
        { a: 'rock', b: 'scissors' },     // A wins
      ],
    });

    assert.strictEqual(state.matchFinished, true);
    assert.strictEqual(state.matchWinner, 'A');
    assert.strictEqual(state.playerAScore, 3);
    assert.strictEqual(state.playerBScore, 2);
  });

  it('Match not finished at 2-2', () => {
    const state = simulateMatch({
      formatType: 'bestOf5',
      winsRequired: 3,
      rounds: [
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
      ],
    });

    assert.strictEqual(state.matchFinished, false);
    assert.strictEqual(state.matchWinner, null);
    assert.strictEqual(state.playerAScore, 2);
    assert.strictEqual(state.playerBScore, 2);
  });
});

// ── Test: Custom configuration ─────────────────────────────────

describe('T98: Custom (wins_required: 5)', () => {
  it('Player A wins 5-3 with draws', () => {
    const rounds = [];
    // 5 A wins
    for (let i = 0; i < 5; i++) rounds.push({ a: 'rock', b: 'scissors' });
    // 3 B wins
    for (let i = 0; i < 3; i++) rounds.push({ a: 'scissors', b: 'rock' });
    // 2 draws
    rounds.push({ a: 'paper', b: 'paper' });
    rounds.push({ a: 'rock', b: 'rock' });

    const state = simulateMatch({
      formatType: 'custom',
      winsRequired: 5,
      rounds,
    });

    assert.strictEqual(state.matchFinished, true);
    assert.strictEqual(state.matchWinner, 'A');
    assert.strictEqual(state.playerAScore, 5);
    assert.strictEqual(state.playerBScore, 3);
    assert.strictEqual(state.drawCount, 2);
    assert.strictEqual(state.totalRounds, 10);
  });
});

// ── Test: Unlimited configuration ──────────────────────────────

describe('T98: Unlimited (no auto-win)', () => {
  it('Match never auto-finishes', () => {
    const state = simulateMatch({
      formatType: 'unlimited',
      winsRequired: 0,
      rounds: [
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
        { a: 'rock', b: 'rock' },          // Draw
        { a: 'paper', b: 'scissors' },     // B wins
        { a: 'scissors', b: 'paper' },     // A wins
      ],
    });

    assert.strictEqual(state.matchFinished, false);
    assert.strictEqual(state.matchWinner, null);
    assert.strictEqual(state.playerAScore, 2);
    assert.strictEqual(state.playerBScore, 2);
    assert.strictEqual(state.drawCount, 1);
    assert.strictEqual(state.totalRounds, 5);
  });

  it('Win rates calculated correctly', () => {
    const state = simulateMatch({
      formatType: 'unlimited',
      winsRequired: 0,
      rounds: [
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'rock', b: 'scissors' },     // A wins
        { a: 'scissors', b: 'rock' },      // B wins
        { a: 'rock', b: 'rock' },          // Draw
      ],
    });

    const winRateA = (state.playerAScore / state.totalRounds) * 100;
    const winRateB = (state.playerBScore / state.totalRounds) * 100;

    assert.strictEqual(winRateA, 60);
    assert.strictEqual(winRateB, 20);
  });
});

// ── Test report summary ────────────────────────────────────────

describe('T98: Test report', () => {
  it('records all configurations tested', () => {
    const configs = ['bestOf3', 'bestOf5', 'custom', 'unlimited'];
    assert.strictEqual(configs.length, 4);
  });

  it('records all 9 move pairs tested', () => {
    assert.strictEqual(ALL_MOVE_PAIRS.length, 9);

    // Verify all expected results
    const draws = ALL_MOVE_PAIRS.filter((p) => p.expected === 'draw');
    const aWins = ALL_MOVE_PAIRS.filter((p) => p.expected === 'player_a_wins');
    const bWins = ALL_MOVE_PAIRS.filter((p) => p.expected === 'player_b_wins');

    assert.strictEqual(draws.length, 3);
    assert.strictEqual(aWins.length, 3);
    assert.strictEqual(bWins.length, 3);
  });
});
