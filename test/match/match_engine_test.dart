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
}