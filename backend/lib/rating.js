/**
 * Rating calculation service (T111).
 *
 * Handles rating updates after ranked matches:
 *   - Win:  +20
 *   - Loss: -20
 *   - Draw: 0
 *   - Rating floor: 0
 */

const { RATING_WIN, RATING_LOSS, RATING_DRAW, RATING_FLOOR } = require('../routes/ranked');

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

  // Update account ratings
  await pool.query('UPDATE account SET rating = $1 WHERE player_id = $2', [newRatingA, playerAId]);
  await pool.query('UPDATE account SET rating = $1 WHERE player_id = $2', [newRatingB, playerBId]);

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

  await pool.query(
    `INSERT INTO match_history (player_id, match_id, opponent_id, mode, format_type, result, rating_before, rating_after)
     SELECT $1, $2, $3, mode, format_type, $4, $5, $6 FROM match WHERE match_id = $2`,
    [playerAId, matchId, playerBId, resultA, currentRatingA, newRatingA]
  );

  await pool.query(
    `INSERT INTO match_history (player_id, match_id, opponent_id, mode, format_type, result, rating_before, rating_after)
     SELECT $1, $2, $3, mode, format_type, $4, $5, $6 FROM match WHERE match_id = $2`,
    [playerBId, matchId, playerAId, resultB, currentRatingB, newRatingB]
  );

  return { newRatingA, newRatingB };
}

/**
 * Update player statistics after a ranked match.
 *
 * @param {Pool} pool - Database pool
 * @param {number} playerAId - Player A's ID
 * @param {number} playerBId - Player B's ID
 * @param {boolean} matchDraw - Whether match was a draw
 * @param {number|null} winnerId - Winner's player ID
 * @param {number} playerAWins - Player A's round wins
 * @param {number} playerBWins - Player B's round wins
 */
async function updatePlayerStatistics(pool, playerAId, playerBId, matchDraw, winnerId, playerAWins, playerBWins) {
  const winnerIdInt = winnerId ? parseInt(winnerId) : null;
  const aWins = parseInt(playerAWins) || 0;
  const bWins = parseInt(playerBWins) || 0;

  if (matchDraw) {
    // Both players get matches_played +1 and draws +1
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1, draws = draws + 1,
       rounds_won = rounds_won + $1, rounds_lost = rounds_lost + $2 WHERE player_id = $3`,
      [aWins, bWins, playerAId]
    );
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1, draws = draws + 1,
       rounds_won = rounds_won + $1, rounds_lost = rounds_lost + $2 WHERE player_id = $3`,
      [bWins, aWins, playerBId]
    );
  } else if (winnerIdInt) {
    const isPlayerAWinner = winnerIdInt === parseInt(playerAId);

    // Winner stats
    const winnerId = isPlayerAWinner ? playerAId : playerBId;
    const winnerRoundWins = isPlayerAWinner ? aWins : bWins;
    const winnerRoundLosses = isPlayerAWinner ? bWins : aWins;
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1, matches_won = matches_won + 1,
       rounds_won = rounds_won + $1, rounds_lost = rounds_lost + $2 WHERE player_id = $3`,
      [winnerRoundWins, winnerRoundLosses, winnerId]
    );

    // Loser stats
    const loserId = isPlayerAWinner ? playerBId : playerAId;
    const loserRoundWins = isPlayerAWinner ? bWins : aWins;
    const loserRoundLosses = isPlayerAWinner ? aWins : bWins;
    await pool.query(
      `UPDATE player_statistic SET matches_played = matches_played + 1, matches_lost = matches_lost + 1,
       rounds_won = rounds_won + $1, rounds_lost = rounds_lost + $2 WHERE player_id = $3`,
      [loserRoundWins, loserRoundLosses, loserId]
    );
  }
}

module.exports = { calculateRatingChanges, applyRatingChanges, updatePlayerStatistics };
