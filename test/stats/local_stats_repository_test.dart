import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rps_arena/features/stats/local_stats_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('winRate is 0.0 when no matches played', () async {
    final repo = LocalStatsRepository();
    final stats = await repo.load();
    expect(stats.winRate, 0.0);
  });

  test('recordStandardMatchResult updates matchesWon and matchesPlayed', () async {
    final repo = LocalStatsRepository();
    await repo.recordStandardMatchResult(playerWon: true);
    final stats = await repo.load();

    expect(stats.matchesPlayed, 1);
    expect(stats.matchesWon, 1);
    expect(stats.matchesLost, 0);
  });

  test('recordUnlimitedMatchResult with draw only increments matchesPlayed',
      () async {
    final repo = LocalStatsRepository();
    await repo.recordUnlimitedMatchResult(winner: null);
    final stats = await repo.load();

    expect(stats.matchesPlayed, 1);
    expect(stats.matchesWon, 0);
    expect(stats.matchesLost, 0);
  });

  test('winRate calculates correctly', () async {
    final repo = LocalStatsRepository();
    await repo.recordStandardMatchResult(playerWon: true);
    await repo.recordStandardMatchResult(playerWon: true);
    await repo.recordStandardMatchResult(playerWon: false);

    final stats = await repo.load();
    expect(stats.matchesPlayed, 3);
    expect(stats.matchesWon, 2);
    expect(stats.winRate, closeTo(66.67, 0.01));
  });

  test('recordMoveSelection increments the right counter', () async {
    final repo = LocalStatsRepository();
    await repo.recordMoveSelection('rock');
    await repo.recordMoveSelection('rock');
    await repo.recordMoveSelection('paper');

    final stats = await repo.load();
    expect(stats.rockSelections, 2);
    expect(stats.paperSelections, 1);
    expect(stats.scissorsSelections, 0);
  });
}