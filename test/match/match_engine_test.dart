import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/match_engine.dart';
import 'package:rps_arena/features/match/domain/match_format.dart';

void main() {
  group('Unlimited match end logic', () {
    test('higher score wins', () {
      final engine = MatchEngine(MatchFormatConfig.unlimited());
      engine.playerAScore = 5;
      engine.playerBScore = 2;
      engine.endUnlimitedMatch();

      expect(engine.matchFinished, true);
      expect(engine.matchWinner, 'A');
    });

    test('equal score produces Match Draw (null winner)', () {
      final engine = MatchEngine(MatchFormatConfig.unlimited());
      engine.playerAScore = 3;
      engine.playerBScore = 3;
      engine.endUnlimitedMatch();

      expect(engine.matchFinished, true);
      expect(engine.matchWinner, isNull);
    });

    test('totalRounds includes wins, losses, and draws', () {
      final engine = MatchEngine(MatchFormatConfig.unlimited());
      engine.playerAScore = 3;
      engine.playerBScore = 2;
      engine.drawCount = 4;

      expect(engine.totalRounds, 9);
    });
  });

  group('Unlimited result calculation', () {
  test('win rates calculate correctly with rounds played', () {
    final engine = MatchEngine(MatchFormatConfig.unlimited());
    engine.playerAScore = 6;
    engine.playerBScore = 3;
    engine.drawCount = 1;
    // totalRounds = 6 + 3 + 1 = 10

    expect(engine.totalRounds, 10);
    expect(engine.playerAWinRate, 60.0);
    expect(engine.playerBWinRate, 30.0);
  });

  test('win rates are 0.0% when no rounds have been played', () {
    final engine = MatchEngine(MatchFormatConfig.unlimited());

    expect(engine.totalRounds, 0);
    expect(engine.playerAWinRate, 0.0);
    expect(engine.playerBWinRate, 0.0);
  });
});
}