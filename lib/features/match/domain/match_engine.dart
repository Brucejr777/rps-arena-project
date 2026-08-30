import 'match_format.dart';

enum RoundPhase {
  scoreDisplay,
  countdown,
  go,
  selecting,
  locked,
  revealing,
  result,
  resultAnimation,
  roundComplete,
}

enum RoundResult { playerAWin, playerBWin, draw }

class MatchEngine {
  final MatchFormatConfig config;

  int playerAScore = 0;
  int playerBScore = 0;
  int currentRoundNumber = 1;
  RoundPhase phase = RoundPhase.scoreDisplay;

  String? playerAMove;
  String? playerBMove;
  RoundResult? lastResult;

  bool matchFinished = false;
  String? matchWinner; // 'A', 'B', or null if unfinished/draw

  MatchEngine(this.config);

  /// Advances through the fixed sequence for a round.
  /// Countdown/timer durations (T14/T16) and draw handling (T13)
  /// get layered onto this in the next tasks.
  void startRound() {
    phase = RoundPhase.scoreDisplay;
    playerAMove = null;
    playerBMove = null;
    lastResult = null;
  }

  void beginCountdown() {
    phase = RoundPhase.countdown;
  }

  void beginSelection() {
    phase = RoundPhase.go;
    phase = RoundPhase.selecting;
  }

  void submitPlayerAMove(String move) {
    playerAMove = move;
  }

  void submitPlayerBMove(String move) {
    playerBMove = move;
  }

  void lockSelections() {
    phase = RoundPhase.locked;
  }

  void reveal() {
    phase = RoundPhase.revealing;
  }

  /// Resolves the round using both submitted moves.
  /// Placeholder resolution logic here — T17 formalizes this into a
  /// dedicated resolution.dart table; this will be swapped to call that.
  void resolveRound() {
    phase = RoundPhase.result;

    final a = playerAMove;
    final b = playerBMove;
    if (a == null || b == null) return;

    if (a == b) {
      lastResult = RoundResult.draw;
    } else if ((a == 'rock' && b == 'scissors') ||
        (a == 'paper' && b == 'rock') ||
        (a == 'scissors' && b == 'paper')) {
      lastResult = RoundResult.playerAWin;
    } else {
      lastResult = RoundResult.playerBWin;
    }

    _applyScore();
    phase = RoundPhase.resultAnimation;
  }

  void _applyScore() {
    if (lastResult == RoundResult.playerAWin) {
      playerAScore++;
    } else if (lastResult == RoundResult.playerBWin) {
      playerBScore++;
    }
    // Draws award no point (T13 formalizes replay/draw-count behavior).
  }

  /// Checks whether the match is complete after this round, and advances
  /// to the next round otherwise.
  void checkMatchCondition() {
    phase = RoundPhase.roundComplete;

    if (config.isUnlimited) {
      // Unlimited: update accumulated stats, continue automatically.
      currentRoundNumber++;
      return;
    }

    if (config.isMatchWon(playerAScore)) {
      matchFinished = true;
      matchWinner = 'A';
    } else if (config.isMatchWon(playerBScore)) {
      matchFinished = true;
      matchWinner = 'B';
    } else {
      currentRoundNumber++;
    }
  }

  /// Manual end for Unlimited matches (T27 wires this to the UI).
  void endUnlimitedMatch() {
    matchFinished = true;
    if (playerAScore > playerBScore) {
      matchWinner = 'A';
    } else if (playerBScore > playerAScore) {
      matchWinner = 'B';
    } else {
      matchWinner = null; // Match Draw
    }
  }
}