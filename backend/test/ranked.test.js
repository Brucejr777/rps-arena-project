const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  RANKED_FORMAT,
  RANKED_WINS_REQUIRED,
  RATING_WIN,
  RATING_LOSS,
  RATING_DRAW,
  RATING_FLOOR,
  RANK_THRESHOLDS,
  getRankForRating,
} = require('../routes/ranked');

describe('Ranked Match configuration (T96)', () => {
  it('uses fixed BEST_OF_3 format', () => {
    assert.strictEqual(RANKED_FORMAT, 'bestOf3');
  });

  it('uses wins_required 2', () => {
    assert.strictEqual(RANKED_WINS_REQUIRED, 2);
  });

  it('rating change: win +20', () => {
    assert.strictEqual(RATING_WIN, 20);
  });

  it('rating change: loss -20', () => {
    assert.strictEqual(RATING_LOSS, -20);
  });

  it('rating change: draw 0', () => {
    assert.strictEqual(RATING_DRAW, 0);
  });

  it('rating floor is 0', () => {
    assert.strictEqual(RATING_FLOOR, 0);
  });

  it('rating never goes below floor', () => {
    const rating = 10;
    const newRating = Math.max(RATING_FLOOR, rating + RATING_LOSS);
    assert.strictEqual(newRating, 0);
  });
});

describe('Rank thresholds (T112)', () => {
  it('Bronze: 0–999', () => {
    assert.strictEqual(getRankForRating(0), 'Bronze');
    assert.strictEqual(getRankForRating(500), 'Bronze');
    assert.strictEqual(getRankForRating(999), 'Bronze');
  });

  it('Silver: 1000–1499', () => {
    assert.strictEqual(getRankForRating(1000), 'Silver');
    assert.strictEqual(getRankForRating(1250), 'Silver');
    assert.strictEqual(getRankForRating(1499), 'Silver');
  });

  it('Gold: 1500–1999', () => {
    assert.strictEqual(getRankForRating(1500), 'Gold');
    assert.strictEqual(getRankForRating(1750), 'Gold');
    assert.strictEqual(getRankForRating(1999), 'Gold');
  });

  it('Platinum: 2000–2499', () => {
    assert.strictEqual(getRankForRating(2000), 'Platinum');
    assert.strictEqual(getRankForRating(2250), 'Platinum');
    assert.strictEqual(getRankForRating(2499), 'Platinum');
  });

  it('Diamond: 2500–2999', () => {
    assert.strictEqual(getRankForRating(2500), 'Diamond');
    assert.strictEqual(getRankForRating(2750), 'Diamond');
    assert.strictEqual(getRankForRating(2999), 'Diamond');
  });

  it('Master: 3000+', () => {
    assert.strictEqual(getRankForRating(3000), 'Master');
    assert.strictEqual(getRankForRating(5000), 'Master');
    assert.strictEqual(getRankForRating(9999), 'Master');
  });
});

describe('Rank thresholds table', () => {
  it('has exactly 6 tiers', () => {
    assert.strictEqual(RANK_THRESHOLDS.length, 6);
  });

  it('is sorted descending by minRating', () => {
    for (let i = 0; i < RANK_THRESHOLDS.length - 1; i++) {
      assert.ok(
        RANK_THRESHOLDS[i].minRating >= RANK_THRESHOLDS[i + 1].minRating,
        `${RANK_THRESHOLDS[i].rank} minRating should be >= ${RANK_THRESHOLDS[i + 1].rank}`
      );
    }
  });

  it('Bronze starts at 0', () => {
    const bronze = RANK_THRESHOLDS.find((t) => t.rank === 'Bronze');
    assert.strictEqual(bronze.minRating, 0);
  });
});
