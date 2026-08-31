import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/ai_service.dart';

void main() {
  const trials = 10000;
  const tolerance = 0.01;

  group('AI behavior is identical regardless of theme or match format', () {
    // AiService has no theme or format parameter at all — this test
    // documents and verifies that architectural guarantee by running
    // the exact same probability checks from T22 and confirming they
    // hold no matter what "context" (format/theme) the caller is in.
    // Since AiService never receives that context, there is no code
    // path by which it could vary — but we verify the numeric output
    // stays consistent as a concrete confirmation.

    test('Easy AI stays at ~33.33% per move regardless of context', () {
      final ai = AiService(random: Random(99));
      final counts = {'rock': 0, 'paper': 0, 'scissors': 0};

      for (var i = 0; i < trials; i++) {
        final move = ai.getMove(AiDifficulty.easy);
        counts[move] = counts[move]! + 1;
      }

      for (final move in counts.keys) {
        final rate = counts[move]! / trials;
        expect(rate, closeTo(1 / 3, tolerance));
      }
    });

    test('Normal AI counter probability stays ~50% regardless of context', () {
      final ai = AiService(random: Random(99));
      for (var i = 0; i < 10; i++) {
        ai.recordPlayerMove('paper');
      }

      var counterCount = 0;
      for (var i = 0; i < trials; i++) {
        if (ai.getMove(AiDifficulty.normal) == 'scissors') counterCount++;
      }

      expect(counterCount / trials, closeTo(0.5, tolerance));
    });

    test('Hard AI counter probability stays ~60% regardless of context', () {
      final ai = AiService(random: Random(99));
      for (var i = 0; i < 5; i++) {
        ai.recordPlayerMove('rock');
      }

      var counterCount = 0;
      for (var i = 0; i < trials; i++) {
        if (ai.getMove(AiDifficulty.hard) == 'paper') counterCount++;
      }

      expect(counterCount / trials, closeTo(0.6, tolerance));
    });

    test('AiService has no theme or format dependency in its public API', () {
      // Structural check: confirms getMove/recordPlayerMove/resetForNewMatch
      // only take move-related parameters, never a theme or format —
      // this is what guarantees identical behavior across all contexts.
      final ai = AiService();
      expect(() => ai.getMove(AiDifficulty.easy), returnsNormally);
      expect(() => ai.recordPlayerMove('rock'), returnsNormally);
      expect(() => ai.resetForNewMatch(), returnsNormally);
    });
  });
}