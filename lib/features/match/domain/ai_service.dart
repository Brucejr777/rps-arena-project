import 'dart:math';

enum AiDifficulty { easy, normal, hard }

class AiService {
  final Random _random = Random();

  /// Move history for the current match, used by Normal/Hard AI.
  /// Easy AI ignores this entirely (no history, no pattern tracking).
  final List<String> _playerMoveHistory = [];

  static const List<String> _moves = ['rock', 'paper', 'scissors'];

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
        // Implemented in T20
        return _easyMove();
      case AiDifficulty.hard:
        // Implemented in T21
        return _easyMove();
    }
  }

  /// Easy AI: ROCK/PAPER/SCISSORS each at 33.33%, no history, no adaptation.
  String _easyMove() {
    return _moves[_random.nextInt(3)];
  }
}