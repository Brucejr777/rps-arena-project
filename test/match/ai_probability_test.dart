import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/ai_service.dart';

void main() {
  const trials = 10000;
  const tolerance = 0.01; // ±1%

  test('Easy AI distributes moves at ~33.33% each with seeded random', () {
  final ai = AiService(random: Random(42));
  final counts = {'rock': 0, 'paper': 0, 'scissors': 0};

  for (var i = 0; i < trials; i++) {
    final move = ai.getMove(AiDifficulty.easy);
    counts[move] = counts[move]! + 1;
  }

  for (final move in counts.keys) {
    final rate = counts[move]! / trials;
    expect(rate, closeTo(1 / 3, tolerance),
        reason: '$move rate was $rate, expected ~33.33%');
  }
});

  test('Normal AI counters most-frequent move at ~50% with seeded random',
      () {
    final ai = AiService(random: Random(42));
    for (var i = 0; i < 10; i++) {
      ai.recordPlayerMove('rock');
    }

    var counterCount = 0;
    for (var i = 0; i < trials; i++) {
      if (ai.getMove(AiDifficulty.normal) == 'paper') counterCount++;
    }

    final rate = counterCount / trials;
    expect(rate, closeTo(0.5, tolerance));
  });

  test('Hard AI counters weighted-predicted move at ~60% with seeded random',
      () {
    final ai = AiService(random: Random(42));
    for (var i = 0; i < 5; i++) {
      ai.recordPlayerMove('scissors');
    }

    var counterCount = 0;
    for (var i = 0; i < trials; i++) {
      if (ai.getMove(AiDifficulty.hard) == 'rock') counterCount++;
    }

    final rate = counterCount / trials;
    expect(rate, closeTo(0.6, tolerance));
  });
}