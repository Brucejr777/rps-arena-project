import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/features/match/domain/match_format.dart';

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
}