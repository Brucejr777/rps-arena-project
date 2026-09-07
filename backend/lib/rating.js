/**
 * Rating calculation service (T111).
 *
 * Handles rating updates after ranked matches:
 *   - Win:  +20
 *   - Loss: -20
 *   - Draw: 0
 *   - Rating floor: 0
 */

const { RATING_WIN, RATING_LOSS, RATING_DRAW, RATING_FLOOR, getRankForRating } = require('../routes/ranked');

/**
 * Calculate rating changes for both players.
 *
 * @param {boolean} matchDraw - Whether the match ended in a draw
 * @param {number|null} winnerId - The winner's player ID, or null for draw
 * @param {number} playerAId - Player A's ID
 * @param {number} playerBId - Player B's ID
 * @returns {{ ratingChangeA: number, ratingChangeB: number }}
 */
function calculateRatingChanges(matchDraw, winnerId, playerAId, playerBId) {
  if (matchDraw) {
    return { ratingChangeA: RATING_DRAW, ratingChangeB: RATING_DRAW };
  }

  if (winnerId === playerAId) {
    // Player A won
    return { ratingChangeA: RATING_WIN, ratingChangeB: RATING_LOSS };
  }

  // Player B won
  return { ratingChangeA: RATING_LOSS, ratingChangeB: RATING_WIN };
}

/**
 * Apply rating changes to both players in the database.
 *
 * @param {Pool} pool - Database pool
 * @param {number} matchId - Match ID
 * @param {number} playerAId - Player A's ID
 * @param {number} playerBId - Player B's ID
 * @param {number} ratingChangeA - Rating change for Player A
 * @param {number} ratingChangeB - Rating change for Player B
 * @returns {Promise<{ newRatingA: number, newRatingB: number }>}
 */
async function applyRatingChanges(pool, matchId, playerAId, playerBId, ratingChangeA, ratingChangeB) {
  // Fetch current ratings
  const ratingsResult = await pool.query(
    'SELECT player_id, rating FROM account WHERE player_id = $1 OR player_id = $2',
    [playerAId, playerBId]
  );

  const ratings = {};
  for (const row of ratingsResult.rows) {
    ratings[row.player_id] = row.rating;
  }

  const currentRatingA = ratings[playerAId] || 1000;
  const currentRatingB = ratings[playerBId] || 1000;

  // Calculate new ratings with floor
  const newRatingA = Math.max(RATING_FLOOR, currentRatingA + ratingChangeA);
  const newRatingB = Math.max(RATING_FLOOR, currentRatingB + ratingChangeB);

  // Calculate new ranks based on ratings
  const newRankA = getRankForRating(newRatingA);
  const newRankB = getRankForRating(newRatingB);

  // Update account ratings and ranks
  await pool.query('UPDATE account SET rating = $1, rank = $2 WHERE player_id = $3', [newRatingA, newRankA, playerAId]);
  await pool.query('UPDATE account SET rating = $1, rank = $2 WHERE player_id = $3', [newRatingB, newRankB, playerBId]);

  // Update leaderboard
  await pool.query(
    'UPDATE leaderboard SET rating = $1, updated_at = NOW() WHERE player_id = $2',
    [newRatingA, playerAId]
  );
  await pool.query(
    'UPDATE leaderboard SET rating = $1, updated_at = NOW() WHERE player_id = $2',
    [newRatingB, playerBId]
  );

  // Update match with rating changes
  await pool.query(
    'UPDATE match SET rating_change_a = $1, rating_change_b = $2 WHERE match_id = $3',
    [ratingChangeA, ratingChangeB, matchId]
  );

  // Record match history for both players
  const isDraw = ratingChangeA === 0 && ratingChangeB === 0;
  const resultA = isDraw ? 'draw' : (ratingChangeA > 0 ? 'win' : 'loss');
  const resultB = isDraw ? 'draw' : (ratingChangeB > 0 ? 'win' : 'loss');

  // Calculate rank changes
  const oldRankA = getRankForRating(currentRatingA);
  const oldRankB = getRankForRating(currentRatingB);
  const rankChangeA = newRankA !== oldRankA ? `${oldRankA} → ${newRankA}` : null;
  const rankChangeB = newRankB !== oldRankB ? `${oldRankB} → ${newRankB}` : null;

  await pool.query(
    `INSERT INTO match_history (player_id, match_id, opponent_id, mode, format_type, result, rating_before, rating_after, rank_change)
     SELECT $1, $2, $3, mode, format_type, $4, $5, $6, $7 FROM match WHERE match_id = $2`,
    [playerAId, matchId, playerBId, resultA, currentRatingA, newRatingA, rankChangeA]
  );

  await pool.query(
    `INSERT INTO match_history (player_id, match_id, opponent_id, mode, format_type, result, rating_before, rating_after, rank_change)
     SELECT $1, $2, $3, mode, format_type, $4, $5, $6, $7 FROM match WHERE match_id = $2`,
    [playerBId, matchId, playerAId, resultB, currentRatingB, newRatingB, rankChangeB]
  );

  return { newRatingA, newRatingB, newRankA, newRankB, rankChangeA, rankChangeB };
}

/**
 * Update player statistics after a match completes.
 *
 * FIX: Now accepts drawCount parameter to properly track round-level draws.
 * The `draws` column represents the number of individual rounds that ended
 * in a draw, NOT match-level draws.
 *
 * @param {Pool} pool - Database pool
 * @param {number} playerAId - Player A's ID
 * @param {number} playerBId - Player B's ID
 * @param {boolean} matchDraw - Whether match was a draw (Unlimited tie)
 * @param {number|null} winnerId - Winner's player ID
 * @param {number} playerAWins - Player A's round wins
 * @param {number} playerBWins - Player B's round wins
 * @param {number} drawCount - Number of rounds that ended in a draw (FIX)
 */
async function updatePlayerStatistics(pool, playerAId, playerBId, matchDraw, winnerId, playerAWins, playerBWins, drawCount = 0) {
  const winnerIdInt = winnerId ? parseInt(winnerId) : null;
  const aWins = parseInt(playerAWins) || 0;
  const bWins = parseInt(playerBWins) || 0;
  const roundsDrawn = parseInt(drawCount) || 0;

  if (matchDraw) {
    // Match-level draw (Unlimited match with equal scores).
    // Both players get matches_played +1.
    // FIX: Use roundsDrawn instead of hardcoded +1 for the draws column.
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1,
       draws = draws + $1,
       rounds_won = rounds_won + $2, rounds_lost = rounds_lost + $3 WHERE player_id = $4`,
      [roundsDrawn, aWins, bWins, playerAId]
    );
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1,
       draws = draws + $1,
       rounds_won = rounds_won + $2, rounds_lost = rounds_lost + $3 WHERE player_id = $4`,
      [roundsDrawn, bWins, aWins, playerBId]
    );
  } else if (winnerIdInt) {
    const isPlayerAWinner = winnerIdInt === parseInt(playerAId);

    // Winner stats
    // FIX: Include draws = draws + roundsDrawn
    const winnerId = isPlayerAWinner ? playerAId : playerBId;
    const winnerRoundWins = isPlayerAWinner ? aWins : bWins;
    const winnerRoundLosses = isPlayerAWinner ? bWins : aWins;
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1, matches_won = matches_won + 1,
       draws = draws + $1,
       rounds_won = rounds_won + $2, rounds_lost = rounds_lost + $3 WHERE player_id = $4`,
      [roundsDrawn, winnerRoundWins, winnerRoundLosses, winnerId]
    );

    // Loser stats
    // FIX: Include draws = draws + roundsDrawn
    const loserId = isPlayerAWinner ? playerBId : playerAId;
    const loserRoundWins = isPlayerAWinner ? bWins : aWins;
    const loserRoundLosses = isPlayerAWinner ? aWins : bWins;
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1, matches_lost = matches_lost + 1,
       draws = draws + $1,
       rounds_won = rounds_won + $2, rounds_lost = rounds_lost + $3 WHERE player_id = $4`,
      [roundsDrawn, loserRoundWins, loserRoundLosses, loserId]
    );
  }
}

/**
 * Track a move selection in player statistics.
 *
 * @param {Pool} pool - Database pool
 * @param {number} playerId - Player's ID
 * @param {string} move - The move: 'rock', 'paper', or 'scissors'
 */
async function trackMoveSelection(pool, playerId, move) {
  const column = `${move}_selections`;
  await pool.query(
    `UPDATE player_statistic SET ${column} = ${column} + 1 WHERE player_id = $1`,
    [playerId]
  );
}

/**
 * Record match history for all online matches (T118).
 * For ranked matches, this is called from applyRatingChanges instead.
 * For non-ranked, rating_before = rating_after (no change).
 *
 * @param {Pool} pool
 * @param {number} matchId
 * @param {number} playerAId
 * @param {number} playerBId
 * @param {boolean} matchDraw
 * @param {number|null} winnerId
 * @param {number} playerAScore
 * @param {number} playerBScore
 */
async function recordMatchHistory(pool, matchId, playerAId, playerBId, matchDraw, winnerId, playerAScore, playerBScore) {
  // Get current ratings for both players
  const ratingsResult = await pool.query(
    'SELECT player_id, rating FROM account WHERE player_id = $1 OR player_id = $2',
    [playerAId, playerBId]
  );

  const ratings = {};
  for (const row of ratingsResult.rows) {
    ratings[row.player_id] = row.rating;
  }

  const ratingA = ratings[playerAId] || 1000;
  const ratingB = ratings[playerBId] || 1000;

  // Determine results (win/loss/draw) based on winner
  let resultA, resultB;
  if (matchDraw) {
    resultA = 'draw';
    resultB = 'draw';
  } else if (winnerId === playerAId) {
    resultA = 'win';
    resultB = 'loss';
  } else {
    resultA = 'loss';
    resultB = 'win';
  }

  // Non-ranked: no rating change, no rank change
  await pool.query(
    `INSERT INTO match_history (player_id, match_id, opponent_id, mode, format_type, result, rating_before, rating_after, rank_change)
     SELECT $1, $2, $3, mode, format_type, $4, $5, $6, NULL FROM match WHERE match_id = $2`,
    [playerAId, matchId, playerBId, resultA, ratingA, ratingA]
  );

  await pool.query(
    `INSERT INTO match_history (player_id, match_id, opponent_id, mode, format_type, result, rating_before, rating_after, rank_change)
     SELECT $1, $2, $3, mode, format_type, $4, $5, $6, NULL FROM match WHERE match_id = $2`,
    [playerBId, matchId, playerAId, resultB, ratingB, ratingB]
  );
}

module.exports = { calculateRatingChanges, applyRatingChanges, updatePlayerStatistics, trackMoveSelection, recordMatchHistory };