import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/resolution.dart';

void main() {
  group('Resolution.resolve', () {
    test('rock vs rock is a draw', () {
      expect(Resolution.resolve('rock', 'rock'), RoundOutcome.draw);
    });

    test('paper vs paper is a draw', () {
      expect(Resolution.resolve('paper', 'paper'), RoundOutcome.draw);
    });

    test('scissors vs scissors is a draw', () {
      expect(Resolution.resolve('scissors', 'scissors'), RoundOutcome.draw);
    });

    test('rock beats scissors', () {
      expect(
        Resolution.resolve('rock', 'scissors'),
        RoundOutcome.playerAWins,
      );
    });

    test('scissors loses to rock (player B wins)', () {
      expect(
        Resolution.resolve('scissors', 'rock'),
        RoundOutcome.playerBWins,
      );
    });

    test('paper beats rock', () {
      expect(
        Resolution.resolve('paper', 'rock'),
        RoundOutcome.playerAWins,
      );
    });

    test('rock loses to paper (player B wins)', () {
      expect(
        Resolution.resolve('rock', 'paper'),
        RoundOutcome.playerBWins,
      );
    });

    test('scissors beats paper', () {
      expect(
        Resolution.resolve('scissors', 'paper'),
        RoundOutcome.playerAWins,
      );
    });

    test('paper loses to scissors (player B wins)', () {
      expect(
        Resolution.resolve('paper', 'scissors'),
        RoundOutcome.playerBWins,
      );
    });
  });
}