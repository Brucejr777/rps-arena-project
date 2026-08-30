import 'match_format.dart';
import 'dart:math';
import 'resolution.dart';
// no new import needed yet — dart:core covers int/bool

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
  int drawCount = 0;
  int countdownValue = 3; // 3, 2, 1, then 0 represents "GO!"
  bool playerASelectionLocked = false;
  bool playerBSelectionLocked = false;
  int selectionSecondsRemaining = 10;
  bool playerAAutoSelected = false;
  bool playerBAutoSelected = false;
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
  playerASelectionLocked = false;
  playerBSelectionLocked = false;
  lastResult = null;
}

  void beginCountdown() {
  phase = RoundPhase.countdown;
  countdownValue = 3;
}

  /// Call once per second while phase == RoundPhase.countdown.
  /// Returns true when the countdown has finished (i.e. GO! has been shown
  /// and it's time to move to selection).
  bool tickCountdown() {
    if (phase != RoundPhase.countdown) return false;

    if (countdownValue > 1) {
      countdownValue--; // 3 -> 2 -> 1
      return false;
    }

    if (countdownValue == 1) {
      countdownValue = 0; // 0 represents "GO!" being shown
      return false;
    }

    // countdownValue == 0 means GO! has already been displayed for its
    // one second — countdown is complete.
    return true;
  }

  /// Call once per second while phase == RoundPhase.selecting.
  /// Returns true when the timer has hit zero and auto-selection should occur.
  bool tickSelectionTimer() {
  if (phase != RoundPhase.selecting) return false;

  if (selectionSecondsRemaining > 0) {
    selectionSecondsRemaining--;
  }

  if (selectionSecondsRemaining <= 0) {
    _autoSelectIfNeeded();
    return true;
  }
  return false;
}

bool get isTimerWarning => selectionSecondsRemaining <= 5;

void _autoSelectIfNeeded() {
  const moves = ['rock', 'paper', 'scissors'];
  final rand = Random();

  if (playerAMove == null) {
    playerAMove = moves[rand.nextInt(3)];
    playerAAutoSelected = true;
    playerASelectionLocked = true;
  }
  if (playerBMove == null) {
    playerBMove = moves[rand.nextInt(3)];
    playerBAutoSelected = true;
    playerBSelectionLocked = true;
  }
}

  void beginSelection() {
  phase = RoundPhase.selecting;
  selectionSecondsRemaining = 10;
  playerAAutoSelected = false;
  playerBAutoSelected = false;
}

  

  void submitPlayerAMove(String move) {
  if (playerASelectionLocked) return; // selection cannot change
  playerAMove = move;
  playerASelectionLocked = true;
}

void submitPlayerBMove(String move) {
  if (playerBSelectionLocked) return;
  playerBMove = move;
  playerBSelectionLocked = true;
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

  final outcome = Resolution.resolve(a, b);
  lastResult = switch (outcome) {
    RoundOutcome.draw => RoundResult.draw,
    RoundOutcome.playerAWins => RoundResult.playerAWin,
    RoundOutcome.playerBWins => RoundResult.playerBWin,
  };

  _applyScore();
  phase = RoundPhase.resultAnimation;
}

  void _applyScore() {
  if (lastResult == RoundResult.playerAWin) {
    playerAScore++;
  } else if (lastResult == RoundResult.playerBWin) {
    playerBScore++;
  } else if (lastResult == RoundResult.draw) {
    drawCount++;
  }
}

  /// Checks whether the match is complete after this round, and advances
  /// to the next round otherwise.
  void checkMatchCondition() {
  phase = RoundPhase.roundComplete;

  // A draw never ends the match and never counts toward winsRequired —
  // it just replays (standard) or accumulates (Unlimited) at the same
  // round number logic below.
  if (lastResult == RoundResult.draw) {
    if (config.isUnlimited) {
      // Unlimited: draw count already incremented, next round begins
      // automatically — no cap on draw count.
      currentRoundNumber++;
    } else {
      // Standard formats: drawn round replays immediately.
      // We don't increment currentRoundNumber, so the same round replays.
    }
    return;
  }

  if (config.isUnlimited) {
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