import 'dart:math';

enum AiDifficulty { easy, normal, hard }

class AiService {
  final Random _random;

  /// Move history for the current match, used by Normal/Hard AI.
  /// Easy AI ignores this entirely (no history, no pattern tracking).
  final List<String> _playerMoveHistory = [];

  static const List<String> _moves = ['rock', 'paper', 'scissors'];
  AiService({Random? random}) : _random = random ?? Random();

  /// Call after each round to record what the player actually played,
  /// so Normal/Hard AI (T20/T21) can use it. Easy AI never reads this.
  void recordPlayerMove(String move) {
    _playerMoveHistory.add(move);
  }

  /// Resets history at the start of a new match — AI must not carry
  /// pattern data between separate matches.
  void resetForNewMatch() {
    _playerMoveHistory.clear();
  }

  String getMove(AiDifficulty difficulty) {
    switch (difficulty) {
      case AiDifficulty.easy:
        return _easyMove();
      case AiDifficulty.normal:
        return _normalMove();
      case AiDifficulty.hard:
        return _hardMove();
    }
  }

  /// Easy AI: ROCK/PAPER/SCISSORS each at 33.33%, no history, no adaptation.
  String _easyMove() {
    return _moves[_random.nextInt(3)];
  }

  /// Normal AI: counters the player's most frequent move.
/// - No recorded moves yet -> equal random (33.33% each).
/// - Tied frequency -> uses the latest move among the tied ones.
/// - Counter probability: 50%, remaining two moves: 25% each.
  String _normalMove() {
    if (_playerMoveHistory.isEmpty) {
      return _easyMove(); // no record uses equal random
    }

    final mostFrequent = _mostFrequentMove(_playerMoveHistory);
    final counter = _counterTo(mostFrequent);

    final roll = _random.nextDouble(); // [0.0, 1.0)
    if (roll < 0.5) {
      return counter;
    }

    // remaining two moves at 25% each
    final others = _moves.where((m) => m != counter).toList();
    return others[_random.nextInt(others.length)];
  }

  /// Returns the move with the highest count in [history].
  /// On a tie, returns the latest (most recently played) move among
  /// the tied moves.
  String _mostFrequentMove(List<String> history) {
    final counts = <String, int>{for (final m in _moves) m: 0};
    for (final move in history) {
      counts[move] = (counts[move] ?? 0) + 1;
    }

    final maxCount = counts.values.reduce(max);
    final tiedMoves =
        counts.entries.where((e) => e.value == maxCount).map((e) => e.key).toSet();

    if (tiedMoves.length == 1) {
      return tiedMoves.first;
    }

    // Tie: scan history from the end, return the first move that's
    // among the tied set — i.e. the latest-played tied move.
    for (var i = history.length - 1; i >= 0; i--) {
      if (tiedMoves.contains(history[i])) {
        return history[i];
      }
    }
    return tiedMoves.first; // fallback, shouldn't be reached
  }

  /// Returns the move that beats [move] (i.e. the counter to it).
  String _counterTo(String move) {
    const counters = {
      'rock': 'paper',
      'paper': 'scissors',
      'scissors': 'rock',
    };
    return counters[move]!;
  }

  /// Hard AI: predicts the player's next move using weighted recent history.
/// - No recorded moves yet -> equal random.
/// - Weight 4 to latest move, 3 to second-latest, 2 to third-latest,
///   1 to every older move.
/// - Predicted move = highest weighted score; ties use latest move among tied.
/// - Counter probability: 60%, remaining two moves: 20% each.
String _hardMove() {
  if (_playerMoveHistory.isEmpty) {
    return _easyMove();
  }

  final predicted = _predictNextMove(_playerMoveHistory);
  final counter = _counterTo(predicted);

  final roll = _random.nextDouble();
  if (roll < 0.6) {
    return counter;
  }

  final others = _moves.where((m) => m != counter).toList();
  return others[_random.nextInt(others.length)];
}

/// Weights the most recent moves higher and returns the move with the
/// highest weighted score. Ties resolve to the latest move among tied.
String _predictNextMove(List<String> history) {
  final scores = <String, int>{for (final m in _moves) m: 0};

  // Walk backward from the most recent move.
  // Position 0 (latest) = weight 4, position 1 = weight 3,
  // position 2 = weight 2, everything older = weight 1.
  for (var i = 0; i < history.length; i++) {
    final move = history[history.length - 1 - i]; // i=0 is latest
    final weight = switch (i) {
      0 => 4,
      1 => 3,
      2 => 2,
      _ => 1,
    };
    scores[move] = (scores[move] ?? 0) + weight;
  }

  final maxScore = scores.values.reduce(max);
  final tied = scores.entries
      .where((e) => e.value == maxScore)
      .map((e) => e.key)
      .toSet();

  if (tied.length == 1) {
    return tied.first;
  }

  // Tie: latest move among tied, scanning history from the end.
  for (var i = history.length - 1; i >= 0; i--) {
    if (tied.contains(history[i])) {
      return history[i];
    }
  }
  return tied.first;
  }

}