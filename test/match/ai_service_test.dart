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
}