import 'match_format.dart';
import 'dart:math';

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
enum RoundOutcome { draw, playerAWins, playerBWins }

class MatchEngine {
  final MatchFormatConfig config;
  int playerAScore = 0;
  int playerBScore = 0;
  int currentRoundNumber = 1;
  int drawCount = 0;
  int countdownValue = 3;
  bool playerASelectionLocked = false;
  bool playerBSelectionLocked = false;
  int selectionSecondsRemaining = 10;
  bool playerAAutoSelected = false;
  bool playerBAutoSelected = false;
  
  String? playerAMove;
  String? playerBMove;
  
  RoundPhase phase = RoundPhase.scoreDisplay;
  RoundResult? lastResult;
  bool matchFinished = false;
  String? matchWinner;
  
  MatchEngine(this.config);
  
  int get totalRounds => playerAScore + playerBScore + drawCount;
  
  double get playerAWinRate {
    if (totalRounds == 0) return 0.0;
    return (playerAScore / totalRounds) * 100;
  }
  
  double get playerBWinRate {
    if (totalRounds == 0) return 0.0;
    return (playerBScore / totalRounds) * 100;
  }
  
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
  
  bool tickCountdown() {
    countdownValue--;
    if (countdownValue < 0) {
      phase = RoundPhase.go;
      return true;
    }
    return false;
  }
  
  void beginSelection() {
    phase = RoundPhase.selecting;
    selectionSecondsRemaining = 10;
    playerAAutoSelected = false;
    playerBAutoSelected = false;
  }

  /// Ticks the selection timer down by one second.
  /// Returns `true` if the timer has reached zero (time's up).
  bool tickSelectionTimer() {
    if (selectionSecondsRemaining > 0) {
      selectionSecondsRemaining--;
    }
    return selectionSecondsRemaining <= 0;
  }

  /// True when the selection timer is at 5 seconds or less,
  /// indicating the UI should show a warning state (e.g., red text).
  bool get isTimerWarning => selectionSecondsRemaining <= 5;
  
  void submitPlayerAMove(String move) {
    if (playerASelectionLocked) return;
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
    final moves = ['rock', 'paper', 'scissors'];
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
  
  void reveal() {
    phase = RoundPhase.revealing;
  }
  
  RoundOutcome _resolve(String moveA, String moveB) {
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
  
  void resolveRound() {
    final outcome = _resolve(playerAMove!, playerBMove!);
    
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
    
    // ── FIX: A draw never ends the match and never counts toward winsRequired ──
    if (lastResult == RoundResult.draw) {
      if (config.isUnlimited) {
        // Unlimited: draw count already incremented, next round begins
        // automatically — no cap on draw count.
        currentRoundNumber++;
      }
      // Standard formats: drawn round replays immediately.
      // We don't increment currentRoundNumber, so the same round replays.
      return;
    }

    if (config.isUnlimited) {
      currentRoundNumber++;
      return;
    }

    if (playerAScore >= config.winsRequired) {
      matchFinished = true;
      matchWinner = 'A';
    } else if (playerBScore >= config.winsRequired) {
      matchFinished = true;
      matchWinner = 'B';
    } else {
      currentRoundNumber++;
    }
  }
  
  void endUnlimitedMatch() {
    matchFinished = true;
    if (playerAScore > playerBScore) {
      matchWinner = 'A';
    } else if (playerBScore > playerAScore) {
      matchWinner = 'B';
    } else {
      matchWinner = null;
    }
  }
}