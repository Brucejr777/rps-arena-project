import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/match_format.dart';
import 'package:rps_arena/features/match/domain/match_engine.dart';

void main() {
  group('MatchFormatConfig.validateCustomWins', () {
    test('accepts minimum boundary (2)', () {
      expect(MatchFormatConfig.validateCustomWins(2), isNull);
    });

    test('accepts maximum boundary (99)', () {
      expect(MatchFormatConfig.validateCustomWins(99), isNull);
    });

    test('rejects below minimum', () {
      expect(MatchFormatConfig.validateCustomWins(1), 'INVALID VALUE');
    });

    test('rejects above maximum', () {
      expect(MatchFormatConfig.validateCustomWins(100), 'INVALID VALUE');
    });

    test('rejects null (unparseable input)', () {
      expect(MatchFormatConfig.validateCustomWins(null), 'INVALID VALUE');
    });
  });

  group('Draw replay and Unlimited draw count', () {
  test('standard format: a draw does not advance the round number', () {
    final engine = MatchEngine(MatchFormatConfig.bestOf3());
    engine.startRound();
    engine.submitPlayerAMove('rock');
    engine.submitPlayerBMove('rock');
    engine.resolveRound();
    final roundBefore = engine.currentRoundNumber;
    engine.checkMatchCondition();

    expect(engine.lastResult, RoundResult.draw);
    expect(engine.currentRoundNumber, roundBefore); // replays, doesn't advance
    expect(engine.drawCount, 1);
  });

  test('unlimited format: a draw increments drawCount and advances round',
      () {
    final engine = MatchEngine(MatchFormatConfig.unlimited());
    engine.startRound();
    engine.submitPlayerAMove('paper');
    engine.submitPlayerBMove('paper');
    engine.resolveRound();
    final roundBefore = engine.currentRoundNumber;
    engine.checkMatchCondition();

    expect(engine.lastResult, RoundResult.draw);
    expect(engine.drawCount, 1);
    expect(engine.currentRoundNumber, roundBefore + 1); // advances
  });
});

group('Selection timer timeout', () {
  test('timer reaching zero auto-selects moves for both players', () {
    final engine = MatchEngine(MatchFormatConfig.bestOf3());
    engine.startRound();
    engine.beginSelection(); // resets timer to 10

    bool timedOut = false;
    for (var i = 0; i < 10; i++) {
      timedOut = engine.tickSelectionTimer();
    }

    expect(timedOut, true);
    expect(engine.playerAMove, isNotNull);
    expect(engine.playerBMove, isNotNull);
    expect(engine.playerAAutoSelected, true);
    expect(engine.playerBAutoSelected, true);
  });

  test('warning state activates at 5 seconds remaining', () {
    final engine = MatchEngine(MatchFormatConfig.bestOf3());
    engine.startRound();
    engine.beginSelection();

    for (var i = 0; i < 5; i++) {
      engine.tickSelectionTimer();
    }

    expect(engine.selectionSecondsRemaining, 5);
    expect(engine.isTimerWarning, true);
  });
});
}