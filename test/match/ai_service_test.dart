import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/ai_service.dart';

void main() {
  test('Easy AI always returns a valid move', () {
    final ai = AiService();
    const validMoves = {'rock', 'paper', 'scissors'};

    for (var i = 0; i < 100; i++) {
      final move = ai.getMove(AiDifficulty.easy);
      expect(validMoves.contains(move), true);
    }
  });
  test('Normal AI counters the most frequent player move most of the time', () {
  final ai = AiService();

  // Player plays rock 10 times — AI should counter with paper most often.
  for (var i = 0; i < 10; i++) {
    ai.recordPlayerMove('rock');
  }

  var paperCount = 0;
  const trials = 2000;
  for (var i = 0; i < trials; i++) {
    if (ai.getMove(AiDifficulty.normal) == 'paper') paperCount++;
  }

  final paperRate = paperCount / trials;
  // Expect roughly 50% (counter probability), allow generous tolerance
  expect(paperRate, closeTo(0.5, 0.05));
});
}