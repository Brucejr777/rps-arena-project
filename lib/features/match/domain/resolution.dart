enum RoundOutcome { playerAWins, playerBWins, draw }

class Resolution {
  Resolution._();

  /// Resolves a round given both players' moves.
  /// Valid moves: 'rock', 'paper', 'scissors'.
  static RoundOutcome resolve(String moveA, String moveB) {
    if (moveA == moveB) return RoundOutcome.draw;

    const beats = {
      'rock': 'scissors',
      'paper': 'rock',
      'scissors': 'paper',
    };

    if (beats[moveA] == moveB) {
      return RoundOutcome.playerAWins;
    }
    return RoundOutcome.playerBWins;
  }
}