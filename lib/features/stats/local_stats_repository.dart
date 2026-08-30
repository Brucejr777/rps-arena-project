import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/local_storage_keys.dart';

class LocalStats {
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int roundsWon;
  final int roundsLost;
  final int draws;
  final int rockSelections;
  final int paperSelections;
  final int scissorsSelections;

  const LocalStats({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.roundsWon = 0,
    this.roundsLost = 0,
    this.draws = 0,
    this.rockSelections = 0,
    this.paperSelections = 0,
    this.scissorsSelections = 0,
  });

  /// Win Rate = Matches Won × 100 ÷ Matches Played.
  /// Matches Played zero displays 0.0%.
  double get winRate {
    if (matchesPlayed == 0) return 0.0;
    return (matchesWon * 100) / matchesPlayed;
  }

  LocalStats copyWith({
    int? matchesPlayed,
    int? matchesWon,
    int? matchesLost,
    int? roundsWon,
    int? roundsLost,
    int? draws,
    int? rockSelections,
    int? paperSelections,
    int? scissorsSelections,
  }) {
    return LocalStats(
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      matchesLost: matchesLost ?? this.matchesLost,
      roundsWon: roundsWon ?? this.roundsWon,
      roundsLost: roundsLost ?? this.roundsLost,
      draws: draws ?? this.draws,
      rockSelections: rockSelections ?? this.rockSelections,
      paperSelections: paperSelections ?? this.paperSelections,
      scissorsSelections: scissorsSelections ?? this.scissorsSelections,
    );
  }

  Map<String, dynamic> toJson() => {
        'matchesPlayed': matchesPlayed,
        'matchesWon': matchesWon,
        'matchesLost': matchesLost,
        'roundsWon': roundsWon,
        'roundsLost': roundsLost,
        'draws': draws,
        'rockSelections': rockSelections,
        'paperSelections': paperSelections,
        'scissorsSelections': scissorsSelections,
      };

  factory LocalStats.fromJson(Map<String, dynamic> json) => LocalStats(
        matchesPlayed: json['matchesPlayed'] ?? 0,
        matchesWon: json['matchesWon'] ?? 0,
        matchesLost: json['matchesLost'] ?? 0,
        roundsWon: json['roundsWon'] ?? 0,
        roundsLost: json['roundsLost'] ?? 0,
        draws: json['draws'] ?? 0,
        rockSelections: json['rockSelections'] ?? 0,
        paperSelections: json['paperSelections'] ?? 0,
        scissorsSelections: json['scissorsSelections'] ?? 0,
      );
}

enum RoundOutcomeForStats { won, lost, drew }

class LocalStatsRepository {
  Future<LocalStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(LocalStorageKeys.localStatistics);
    if (raw == null) return const LocalStats();
    return LocalStats.fromJson(jsonDecode(raw));
  }

  Future<void> _save(LocalStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      LocalStorageKeys.localStatistics,
      jsonEncode(stats.toJson()),
    );
  }

  /// Records a single move selection (rock/paper/scissors) toward the
  /// running move-count stats.
  Future<void> recordMoveSelection(String move) async {
    final current = await load();
    final updated = switch (move) {
      'rock' =>
        current.copyWith(rockSelections: current.rockSelections + 1),
      'paper' =>
        current.copyWith(paperSelections: current.paperSelections + 1),
      'scissors' =>
        current.copyWith(scissorsSelections: current.scissorsSelections + 1),
      _ => current,
    };
    await _save(updated);
  }

  /// Records the outcome of a single round (win/loss/draw) toward
  /// rounds won/lost/draws.
  Future<void> recordRoundOutcome(RoundOutcomeForStats outcome) async {
    final current = await load();
    final updated = switch (outcome) {
      RoundOutcomeForStats.won =>
        current.copyWith(roundsWon: current.roundsWon + 1),
      RoundOutcomeForStats.lost =>
        current.copyWith(roundsLost: current.roundsLost + 1),
      RoundOutcomeForStats.drew =>
        current.copyWith(draws: current.draws + 1),
    };
    await _save(updated);
  }

  /// Records a completed standard match (has a clear winner/loser).
  Future<void> recordStandardMatchResult({required bool playerWon}) async {
    final current = await load();
    final updated = playerWon
        ? current.copyWith(
            matchesPlayed: current.matchesPlayed + 1,
            matchesWon: current.matchesWon + 1,
          )
        : current.copyWith(
            matchesPlayed: current.matchesPlayed + 1,
            matchesLost: current.matchesLost + 1,
          );
    await _save(updated);
  }

  /// Records a completed Unlimited match. A draw only increments
  /// matches played (no win/loss).
  Future<void> recordUnlimitedMatchResult({required String? winner}) async {
    final current = await load();
    LocalStats updated;
    if (winner == null) {
      // Unlimited Match Draw increments matches played only.
      updated = current.copyWith(matchesPlayed: current.matchesPlayed + 1);
    } else if (winner == 'A') {
      updated = current.copyWith(
        matchesPlayed: current.matchesPlayed + 1,
        matchesWon: current.matchesWon + 1,
      );
    } else {
      updated = current.copyWith(
        matchesPlayed: current.matchesPlayed + 1,
        matchesLost: current.matchesLost + 1,
      );
    }
    await _save(updated);
  }

  Future<void> resetLocalStatistics() async {
    await _save(const LocalStats());
  }
}