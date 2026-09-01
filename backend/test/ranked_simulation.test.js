/**
 * T123 — Automated ranked simulation test.
 *
 * Simulates a full Best-of-3 ranked match between two test accounts,
 * verifying: result, rating change, rank threshold, leaderboard, match history.
 *
 * Uses the core modules directly (resolution, rating, queue) since
 * the full endpoint requires a running database.
 */

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { resolveRound } = require('../lib/resolution');
const { calculateRatingChanges } = require('../lib/rating');
const {
  getRankForRating,
  RATING_WIN,
  RATING_LOSS,
  RATING_FLOOR,
} = require('../routes/ranked');

// ── Test accounts ──────────────────────────────────────────────────

const ALICE = { id: 1, username: 'Alice', rating: 1000, rank: 'Silver' };
const BOB = { id: 2, username: 'Bob', rating: 1000, rank: 'Silver' };

// ── Simulate ranked match ──────────────────────────────────────────

function simulateRankedMatch(playerA, playerB, rounds) {
  let aScore = 0;
  let bScore = 0;
  const results = [];

  for (const round of rounds) {
    const result = resolveRound(round.a, round.b);
    if (result === 'player_a_wins') aScore++;
    if (result === 'player_b_wins') bScore++;
    results.push({ round: results.length + 1, a: round.a, b: round.b, result, aScore, bScore });

    if (aScore >= 2 || bScore >= 2) break; // Best-of-3
  }

  const matchDraw = false;
  const winnerId = aScore >= 2 ? playerA.id : (bScore >= 2 ? playerB.id : null);

  // Calculate rating changes
  const { ratingChangeA, ratingChangeB } = calculateRatingChanges(matchDraw, winnerId, playerA.id, playerB.id);
  const newRatingA = Math.max(RATING_FLOOR, playerA.rating + ratingChangeA);
  const newRatingB = Math.max(RATING_FLOOR, playerB.rating + ratingChangeB);
  const newRankA = getRankForRating(newRatingA);
  const newRankB = getRankForRating(newRatingB);

  // Record match history
  const historyA = {
    playerId: playerA.id,
    opponentId: playerB.id,
    result: winnerId === playerA.id ? 'win' : 'loss',
    ratingBefore: playerA.rating,
    ratingAfter: newRatingA,
    rankChange: newRankA !== playerA.rank ? `${playerA.rank} → ${newRankA}` : null,
  };
  const historyB = {
    playerId: playerB.id,
    opponentId: playerA.id,
    result: winnerId === playerB.id ? 'win' : 'loss',
    ratingBefore: playerB.rating,
    ratingAfter: newRatingB,
    rankChange: newRankB !== playerB.rank ? `${playerB.rank} → ${newRankB}` : null,
  };

  return {
    winnerId,
    matchDraw,
    aScore,
    bScore,
    totalRounds: results.length,
    results,
    ratingChangeA,
    ratingChangeB,
    newRatingA,
    newRatingB,
    newRankA,
    newRankB,
    historyA,
    historyB,
  };
}

// ── Tests ──────────────────────────────────────────────────────────

describe('T123: Ranked simulation — Best-of-3', () => {
  it('Alice wins 2-0 (rock beats scissors twice)', () => {
    const alice = { ...ALICE };
    const bob = { ...BOB };

    const match = simulateRankedMatch(alice, bob, [
      { a: 'rock', b: 'scissors' },     // Alice wins
      { a: 'rock', b: 'scissors' },     // Alice wins
    ]);

    assert.equal(match.winnerId, alice.id, 'Alice should win');
    assert.equal(match.aScore, 2);
    assert.equal(match.bScore, 0);
    assert.equal(match.totalRounds, 2);
    assert.equal(match.ratingChangeA, RATING_WIN, 'Alice gains +20');
    assert.equal(match.ratingChangeB, RATING_LOSS, 'Bob loses -20');
    assert.equal(match.newRatingA, 1020, 'Alice: 1000 → 1020');
    assert.equal(match.newRatingB, 980, 'Bob: 1000 → 980');
    assert.equal(match.newRankA, 'Silver', 'Alice stays Silver');
    assert.equal(match.newRankB, 'Bronze', 'Bob drops to Bronze');
  });

  it('Alice wins 2-1 (best-of-3 with draws)', () => {
    const alice = { ...ALICE };
    const bob = { ...BOB };

    const match = simulateRankedMatch(alice, bob, [
      { a: 'rock', b: 'rock' },         // Draw
      { a: 'rock', b: 'scissors' },     // Alice wins
      { a: 'paper', b: 'rock' },        // Alice wins
    ]);

    assert.equal(match.winnerId, alice.id, 'Alice should win');
    assert.equal(match.aScore, 2);
    assert.equal(match.bScore, 0);
    assert.equal(match.totalRounds, 3, '3 rounds played (1 draw + 2 wins)');
    assert.equal(match.newRatingA, 1020, 'Alice: 1000 → 1020');
    assert.equal(match.newRatingB, 980, 'Bob: 1000 → 980');
  });

  it('Bob wins 2-1 (upset)', () => {
    const alice = { ...ALICE };
    const bob = { ...BOB };

    const match = simulateRankedMatch(alice, bob, [
      { a: 'paper', b: 'scissors' },    // Bob wins
      { a: 'rock', b: 'scissors' },     // Alice wins
      { a: 'paper', b: 'scissors' },    // Bob wins
    ]);

    assert.equal(match.winnerId, bob.id, 'Bob should win');
    assert.equal(match.aScore, 1);
    assert.equal(match.bScore, 2);
    assert.equal(match.ratingChangeA, RATING_LOSS, 'Alice loses -20');
    assert.equal(match.ratingChangeB, RATING_WIN, 'Bob gains +20');
    assert.equal(match.newRatingA, 980, 'Alice: 1000 → 980');
    assert.equal(match.newRatingB, 1020, 'Bob: 1000 → 1020');
    assert.equal(match.newRankA, 'Bronze', 'Alice drops to Bronze');
    assert.equal(match.newRankB, 'Silver', 'Bob stays Silver');
  });

  it('Match history records correctly for both players', () => {
    const alice = { ...ALICE };
    const bob = { ...BOB };

    const match = simulateRankedMatch(alice, bob, [
      { a: 'rock', b: 'scissors' },     // Alice wins
      { a: 'rock', b: 'scissors' },     // Alice wins
    ]);

    // Alice's history
    assert.equal(match.historyA.result, 'win');
    assert.equal(match.historyA.ratingBefore, 1000);
    assert.equal(match.historyA.ratingAfter, 1020);
    assert.equal(match.historyA.rankChange, null, 'No rank change within Silver');

    // Bob's history
    assert.equal(match.historyB.result, 'loss');
    assert.equal(match.historyB.ratingBefore, 1000);
    assert.equal(match.historyB.ratingAfter, 980);
    assert.equal(match.historyB.rankChange, 'Silver → Bronze', 'Bob demotes');
  });
});

describe('T123: Rating floor enforcement', () => {
  it('Rating cannot go below 0', () => {
    const lowPlayer = { id: 3, username: 'LowPlayer', rating: 5, rank: 'Bronze' };
    const opponent = { id: 4, username: 'Opponent', rating: 1000, rank: 'Silver' };

    const { ratingChangeA, ratingChangeB } = calculateRatingChanges(false, opponent.id, lowPlayer.id, opponent.id);
    const newRating = Math.max(RATING_FLOOR, lowPlayer.rating + ratingChangeA);

    assert.equal(newRating, 0, 'Rating floored at 0');
  });

  it('Rating 1000 player losing drops to 980 (Bronze)', () => {
    const { ratingChangeA } = calculateRatingChanges(false, BOB.id, ALICE.id, BOB.id);
    const newRating = Math.max(RATING_FLOOR, ALICE.rating + ratingChangeA);
    assert.equal(newRating, 980);
    assert.equal(getRankForRating(newRating), 'Bronze');
  });
});

describe('T123: Rank threshold transitions', () => {
  it('Bronze → Silver at rating 1000', () => {
    assert.equal(getRankForRating(999), 'Bronze');
    assert.equal(getRankForRating(1000), 'Silver');
  });

  it('Silver → Gold at rating 1500', () => {
    assert.equal(getRankForRating(1499), 'Silver');
    assert.equal(getRankForRating(1500), 'Gold');
  });

  it('Gold → Platinum at rating 2000', () => {
    assert.equal(getRankForRating(1999), 'Gold');
    assert.equal(getRankForRating(2000), 'Platinum');
  });

  it('Platinum → Diamond at rating 2500', () => {
    assert.equal(getRankForRating(2499), 'Platinum');
    assert.equal(getRankForRating(2500), 'Diamond');
  });

  it('Diamond → Master at rating 3000', () => {
    assert.equal(getRankForRating(2999), 'Diamond');
    assert.equal(getRankForRating(3000), 'Master');
  });
});

describe('T123: Simulated leaderboard after matches', () => {
  it('Leaderboard reflects cumulative rating changes', () => {
    // Simulate multiple matches between Alice and Bob
    let alice = { ...ALICE };
    let bob = { ...BOB };

    // Match 1: Alice wins
    const m1 = simulateRankedMatch(alice, bob, [
      { a: 'rock', b: 'scissors' },
      { a: 'rock', b: 'scissors' },
    ]);
    alice.rating = m1.newRatingA;
    bob.rating = m1.newRatingB;
    alice.rank = m1.newRankA;
    bob.rank = m1.newRankB;

    assert.equal(alice.rating, 1020, 'Alice: 1020 after match 1');
    assert.equal(bob.rating, 980, 'Bob: 980 after match 1');

    // Match 2: Bob wins
    const m2 = simulateRankedMatch(alice, bob, [
      { a: 'paper', b: 'scissors' },
      { a: 'paper', b: 'scissors' },
    ]);
    alice.rating = m2.newRatingA;
    bob.rating = m2.newRatingB;

    assert.equal(alice.rating, 1000, 'Alice: 1000 after match 2');
    assert.equal(bob.rating, 1000, 'Bob: 1000 after match 2');

    // Leaderboard: both at 1000, tied
    const leaderboard = [
      { playerId: alice.id, username: alice.username, rating: alice.rating },
      { playerId: bob.id, username: bob.username, rating: bob.rating },
    ].sort((a, b) => b.rating - a.rating);

    assert.equal(leaderboard[0].rating, leaderboard[1].rating, 'Tied at 1000');
  });

  it('Win streak promotes to higher rank', () => {
    let alice = { ...ALICE }; // Start at 1000 (Silver)
    const bob = { ...BOB };

    // Win 25 matches in a row → 1000 + 25*20 = 1500 (Gold)
    for (let i = 0; i < 25; i++) {
      const m = simulateRankedMatch(alice, bob, [
        { a: 'rock', b: 'scissors' },
        { a: 'rock', b: 'scissors' },
      ]);
      alice.rating = m.newRatingA;
      alice.rank = m.newRankA;
    }

    assert.equal(alice.rating, 1500, 'Alice reaches 1500 after 25 wins');
    assert.equal(alice.rank, 'Gold', 'Alice promoted to Gold');
  });
});
