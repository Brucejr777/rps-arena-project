/**
 * T111/T112 — Rating changes and rank threshold tests.
 *
 * Verifies:
 *   - Ranked Win: +20
 *   - Ranked Loss: -20
 *   - Draw: 0
 *   - Rating floor: 0
 *   - Rank updates when rating crosses thresholds
 */

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  calculateRatingChanges,
  applyRatingChanges,
  updatePlayerStatistics,
} = require('../lib/rating');
const { RATING_WIN, RATING_LOSS, RATING_DRAW, RATING_FLOOR, getRankForRating } = require('../routes/ranked');

// ── Pure calculation tests ─────────────────────────────────────────

describe('calculateRatingChanges', () => {
  it('returns +20/-20 when Player A wins', () => {
    const result = calculateRatingChanges(false, 1, 1, 2);
    assert.equal(result.ratingChangeA, RATING_WIN);
    assert.equal(result.ratingChangeB, RATING_LOSS);
  });

  it('returns -20/+20 when Player B wins', () => {
    const result = calculateRatingChanges(false, 2, 1, 2);
    assert.equal(result.ratingChangeA, RATING_LOSS);
    assert.equal(result.ratingChangeB, RATING_WIN);
  });

  it('returns 0/0 on a draw', () => {
    const result = calculateRatingChanges(true, null, 1, 2);
    assert.equal(result.ratingChangeA, RATING_DRAW);
    assert.equal(result.ratingChangeB, RATING_DRAW);
  });

  it('RATING_WIN is +20', () => {
    assert.equal(RATING_WIN, 20);
  });

  it('RATING_LOSS is -20', () => {
    assert.equal(RATING_LOSS, -20);
  });

  it('RATING_DRAW is 0', () => {
    assert.equal(RATING_DRAW, 0);
  });

  it('RATING_FLOOR is 0', () => {
    assert.equal(RATING_FLOOR, 0);
  });
});

// ── Database integration tests ─────────────────────────────────────

describe('applyRatingChanges (database)', () => {
  // In-memory mock pool for testing
  function createMockPool() {
    const accounts = {
      1: { player_id: 1, rating: 1000 },
      2: { player_id: 2, rating: 1000 },
      3: { player_id: 3, rating: 5 },
    };
    const leaderboard = {
      1: { player_id: 1, rating: 1000 },
      2: { player_id: 2, rating: 1000 },
      3: { player_id: 3, rating: 5 },
    };
    const matchHistory = [];
    const matches = {};

    return {
      accounts,
      leaderboard,
      matchHistory,
      matches,
      query(sql, params) {
        // SELECT player_id, rating FROM account
        if (sql.includes('SELECT player_id, rating FROM account')) {
          const rows = params
            .filter((p) => typeof p === 'number')
            .map((id) => accounts[id] ? { player_id: id, rating: accounts[id].rating } : null)
            .filter(Boolean);
          return Promise.resolve({ rows });
        }
        // UPDATE account SET rating (with optional rank)
        if (sql.includes('UPDATE account SET rating')) {
          if (sql.includes('rank =')) {
            // T112: rating + rank update
            const [rating, rank, playerId] = params;
            if (accounts[playerId]) {
              accounts[playerId].rating = rating;
              accounts[playerId].rank = rank;
            }
          } else {
            const [rating, playerId] = params;
            if (accounts[playerId]) accounts[playerId].rating = rating;
          }
          return Promise.resolve({ rows: [] });
        }
        // UPDATE leaderboard SET rating
        if (sql.includes('UPDATE leaderboard SET rating')) {
          const [rating, playerId] = params;
          if (leaderboard[playerId]) leaderboard[playerId].rating = rating;
          return Promise.resolve({ rows: [] });
        }
        // UPDATE match SET rating_change_a
        if (sql.includes('UPDATE match SET rating_change_a')) {
          const matchId = params[2];
          if (!matches[matchId]) matches[matchId] = {};
          matches[matchId].rating_change_a = params[0];
          matches[matchId].rating_change_b = params[1];
          return Promise.resolve({ rows: [] });
        }
        // INSERT INTO match_history
        if (sql.includes('INSERT INTO match_history')) {
          matchHistory.push({
            player_id: params[0],
            match_id: params[1],
            result: params[3],
            rating_before: params[4],
            rating_after: params[5],
            rank_change: params[6] || null,
          });
          return Promise.resolve({ rows: [] });
        }
        // SELECT mode, format_type FROM match
        if (sql.includes('SELECT mode, format_type FROM match')) {
          return Promise.resolve({ rows: [{ mode: 'ranked', format_type: 'bestOf3' }] });
        }
        return Promise.resolve({ rows: [] });
      },
    };
  }

  it('applies +20/-20 on Player A win', async () => {
    const pool = createMockPool();
    const { newRatingA, newRatingB } = await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(newRatingA, 1020);
    assert.equal(newRatingB, 980);
    assert.equal(pool.accounts[1].rating, 1020);
    assert.equal(pool.accounts[2].rating, 980);
  });

  it('applies -20/+20 on Player B win', async () => {
    const pool = createMockPool();
    const { newRatingA, newRatingB } = await applyRatingChanges(pool, 1, 1, 2, -20, 20);
    assert.equal(newRatingA, 980);
    assert.equal(newRatingB, 1020);
  });

  it('applies 0/0 on draw', async () => {
    const pool = createMockPool();
    const { newRatingA, newRatingB } = await applyRatingChanges(pool, 1, 1, 2, 0, 0);
    assert.equal(newRatingA, 1000);
    assert.equal(newRatingB, 1000);
  });

  it('enforces rating floor at 0', async () => {
    const pool = createMockPool();
    // Player 3 starts at 5, losing 20 should floor at 0
    const { newRatingA, newRatingB } = await applyRatingChanges(pool, 1, 3, 1, -20, 20);
    assert.equal(newRatingA, 0);
    assert.equal(newRatingB, 1020);
  });

  it('rating floor does not affect normal ratings', async () => {
    const pool = createMockPool();
    // Player 1 at 1000, losing 20 = 980 (well above floor)
    const { newRatingA } = await applyRatingChanges(pool, 1, 1, 2, -20, 20);
    assert.equal(newRatingA, 980);
  });

  it('updates leaderboard table', async () => {
    const pool = createMockPool();
    await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(pool.leaderboard[1].rating, 1020);
    assert.equal(pool.leaderboard[2].rating, 980);
  });

  it('updates rank when rating crosses threshold', async () => {
    const pool = createMockPool();
    // Player 2 at 1000 (Silver), loses 20 → 980 (Bronze)
    const result1 = await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(result1.newRankB, 'Bronze'); // Demoted to Bronze

    // Player 2 at 980 (Bronze), wins 20 → 1000 (Silver)
    pool.accounts[2].rating = 980;
    pool.accounts[2].rank = 'Bronze';
    pool.leaderboard[2].rating = 980;
    const result2 = await applyRatingChanges(pool, 2, 1, 2, -20, 20);
    assert.equal(result2.newRankB, 'Silver'); // Promoted to Silver
  });

  it('stores rating changes in match record', async () => {
    const pool = createMockPool();
    await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(pool.matches[1].rating_change_a, 20);
    assert.equal(pool.matches[1].rating_change_b, -20);
  });

  it('records match history for both players', async () => {
    const pool = createMockPool();
    await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(pool.matchHistory.length, 2);

    const histA = pool.matchHistory.find((h) => h.player_id === 1);
    assert.equal(histA.result, 'win');
    assert.equal(histA.rating_before, 1000);
    assert.equal(histA.rating_after, 1020);

    const histB = pool.matchHistory.find((h) => h.player_id === 2);
    assert.equal(histB.result, 'loss');
    assert.equal(histB.rating_before, 1000);
    assert.equal(histB.rating_after, 980);
  });

  it('records draw in match history', async () => {
    const pool = createMockPool();
    await applyRatingChanges(pool, 1, 1, 2, 0, 0);
    assert.equal(pool.matchHistory.length, 2);
    assert.equal(pool.matchHistory[0].result, 'draw');
    assert.equal(pool.matchHistory[1].result, 'draw');
  });

  it('records rank_change in match history when rank changes', async () => {
    const pool = createMockPool();
    // Set up player 1 to promote from Silver to Gold (1480 → 1500)
    pool.accounts[1].rating = 1480;
    pool.accounts[1].rank = 'Silver';
    pool.leaderboard[1].rating = 1480;
      const result = await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(result.rankChangeA, 'Silver → Gold');
    assert.equal(pool.matchHistory[0].rank_change, 'Silver → Gold');
  });

  it('no rank_change when rating stays in same tier', async () => {
    const pool = createMockPool();
    // Set both players well within Silver (1200) so +20/-20 keeps them in Silver
    pool.accounts[1].rating = 1200;
    pool.accounts[1].rank = 'Silver';
    pool.accounts[2].rating = 1200;
    pool.accounts[2].rank = 'Silver';
    pool.leaderboard[1].rating = 1200;
    pool.leaderboard[2].rating = 1200;
    const result = await applyRatingChanges(pool, 1, 1, 2, 20, -20);
    assert.equal(result.rankChangeA, null);
    assert.equal(result.rankChangeB, null);
  });
});

// ── Rank threshold tests ──────────────────────────────────────────

describe('Rank threshold updates (T112)', () => {
  it('getRankForRating returns correct ranks for all tiers', () => {
    assert.equal(getRankForRating(0), 'Bronze');
    assert.equal(getRankForRating(500), 'Bronze');
    assert.equal(getRankForRating(999), 'Bronze');
    assert.equal(getRankForRating(1000), 'Silver');
    assert.equal(getRankForRating(1250), 'Silver');
    assert.equal(getRankForRating(1499), 'Silver');
    assert.equal(getRankForRating(1500), 'Gold');
    assert.equal(getRankForRating(1750), 'Gold');
    assert.equal(getRankForRating(1999), 'Gold');
    assert.equal(getRankForRating(2000), 'Platinum');
    assert.equal(getRankForRating(2250), 'Platinum');
    assert.equal(getRankForRating(2499), 'Platinum');
    assert.equal(getRankForRating(2500), 'Diamond');
    assert.equal(getRankForRating(2750), 'Diamond');
    assert.equal(getRankForRating(2999), 'Diamond');
    assert.equal(getRankForRating(3000), 'Master');
    assert.equal(getRankForRating(5000), 'Master');
  });

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

  it('rating drop demotes rank', () => {
    assert.equal(getRankForRating(1000), 'Silver');
    assert.equal(getRankForRating(999), 'Bronze');
  });
});

// ── Multiple consecutive rating changes ────────────────────────────

describe('Rating across multiple matches', () => {
  function createMockPool() {
    const accounts = {
      1: { player_id: 1, rating: 1000 },
      2: { player_id: 2, rating: 1000 },
    };
    const leaderboard = {
      1: { player_id: 1, rating: 1000 },
      2: { player_id: 2, rating: 1000 },
    };
    const matchHistory = [];
    const matches = {};

    return {
      accounts,
      leaderboard,
      matchHistory,
      matches,
      query(sql, params) {
        if (sql.includes('SELECT player_id, rating FROM account')) {
          const rows = params
            .filter((p) => typeof p === 'number')
            .map((id) => accounts[id] ? { player_id: id, rating: accounts[id].rating } : null)
            .filter(Boolean);
          return Promise.resolve({ rows });
        }
        if (sql.includes('UPDATE account SET rating')) {
          if (sql.includes('rank =')) {
            const [rating, rank, playerId] = params;
            if (accounts[playerId]) {
              accounts[playerId].rating = rating;
              accounts[playerId].rank = rank;
            }
          } else {
            const [rating, playerId] = params;
            if (accounts[playerId]) accounts[playerId].rating = rating;
          }
          return Promise.resolve({ rows: [] });
        }
        if (sql.includes('UPDATE leaderboard SET rating')) {
          const [rating, playerId] = params;
          if (leaderboard[playerId]) leaderboard[playerId].rating = rating;
          return Promise.resolve({ rows: [] });
        }
        if (sql.includes('UPDATE match SET rating_change_a')) {
          const matchId = params[2];
          if (!matches[matchId]) matches[matchId] = {};
          matches[matchId].rating_change_a = params[0];
          matches[matchId].rating_change_b = params[1];
          return Promise.resolve({ rows: [] });
        }
        if (sql.includes('INSERT INTO match_history')) {
          matchHistory.push({ player_id: params[0], match_id: params[1] });
          return Promise.resolve({ rows: [] });
        }
        if (sql.includes('SELECT mode, format_type FROM match')) {
          return Promise.resolve({ rows: [{ mode: 'ranked', format_type: 'bestOf3' }] });
        }
        return Promise.resolve({ rows: [] });
      },
    };
  }

  it('Player A wins 3 consecutive matches: 1000 → 1060', async () => {
    const pool = createMockPool();
    for (let i = 1; i <= 3; i++) {
      await applyRatingChanges(pool, i, 1, 2, 20, -20);
    }
    assert.equal(pool.accounts[1].rating, 1060);
    assert.equal(pool.accounts[2].rating, 940);
  });

  it('Mixed results: Win, Loss, Draw for Player A: 1000 → 1000', async () => {
    const pool = createMockPool();
    await applyRatingChanges(pool, 1, 1, 2, 20, -20);  // A wins
    await applyRatingChanges(pool, 2, 1, 2, -20, 20);  // A loses
    await applyRatingChanges(pool, 3, 1, 2, 0, 0);     // Draw
    assert.equal(pool.accounts[1].rating, 1000);
    assert.equal(pool.accounts[2].rating, 1000);
  });

  it('Rating floor persists across multiple losses', async () => {
    const pool = createMockPool();
    // Player 1: 1000 → 980 → 960 → ... → 0 (after 50 losses)
    // But let's just test that it floors at 0
    await applyRatingChanges(pool, 1, 1, 2, -20, 20);  // 1000 → 980
    assert.equal(pool.accounts[1].rating, 980);

    // Simulate player at rating 5 losing
    pool.accounts[1].rating = 5;
    pool.leaderboard[1].rating = 5;
    await applyRatingChanges(pool, 2, 1, 2, -20, 20);  // 5 → 0 (floored)
    assert.equal(pool.accounts[1].rating, 0);
  });
});
