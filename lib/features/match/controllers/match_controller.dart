import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MatchMode { offline, online, ranked }

class MatchState {
  final MatchMode mode;
  final bool isPaused;
  final bool timersRunning;
  final bool bothPlayersReady;

  const MatchState({
    required this.mode,
    this.isPaused = false,
    this.timersRunning = true,
    this.bothPlayersReady = false,
  });

  MatchState copyWith({
    bool? isPaused,
    bool? timersRunning,
    bool? bothPlayersReady,
  }) {
    return MatchState(
      mode: mode,
      isPaused: isPaused ?? this.isPaused,
      timersRunning: timersRunning ?? this.timersRunning,
      bothPlayersReady: bothPlayersReady ?? this.bothPlayersReady,
    );
  }
}

enum ExitOutcome { resumed, exitedCleanly, connectionLost, rankedQuitLoss }

class MatchController extends Notifier<MatchState> {
  @override
  MatchState build() {
    return const MatchState(mode: MatchMode.offline);
  }

  /// Call once when a gameplay screen starts, to set which mode this match is.
  void setMode(MatchMode mode) {
    state = MatchState(mode: mode);
  }

  void pause() {
    if (state.mode == MatchMode.offline) {
      state = state.copyWith(isPaused: true, timersRunning: false);
    } else {
      state = state.copyWith(isPaused: true);
    }
  }

  void resume() {
    state = state.copyWith(isPaused: false, timersRunning: true);
  }

  void markBothReady() {
    state = state.copyWith(bothPlayersReady: true);
  }

  ExitOutcome attemptExit() {
    switch (state.mode) {
      case MatchMode.offline:
        return ExitOutcome.exitedCleanly;
      case MatchMode.online:
        return ExitOutcome.connectionLost;
      case MatchMode.ranked:
        if (state.bothPlayersReady) {
          return ExitOutcome.rankedQuitLoss;
        }
        return ExitOutcome.exitedCleanly;
    }
  }
}

final matchControllerProvider =
    NotifierProvider<MatchController, MatchState>(MatchController.new);