/**
 * Server-side round resolution (T97).
 *
 * Mirrors the Flutter client's Resolution.resolve():
 *   - ROCK beats SCISSORS
 *   - PAPER beats ROCK
 *   - SCISSORS beats PAPER
 *   - Same move = draw
 *
 * @returns {'player_a_wins' | 'player_b_wins' | 'draw'}
 */
function resolveRound(moveA, moveB) {
  if (moveA === moveB) return 'draw';

  const beats = {
    rock: 'scissors',
    paper: 'rock',
    scissors: 'paper',
  };

  if (beats[moveA] === moveB) return 'player_a_wins';
  return 'player_b_wins';
}

module.exports = { resolveRound };
