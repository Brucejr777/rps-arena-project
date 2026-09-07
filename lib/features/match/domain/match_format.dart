enum MatchFormat { bestOf3, bestOf5, bestOf7, bestOf9, custom, unlimited }

class MatchFormatConfig {
  static const int minCustomWins = 2;
  static const int maxCustomWins = 99;

  final MatchFormat format;
  final int winsRequired;

  const MatchFormatConfig({
    required this.format,
    required this.winsRequired,
  });

  /// Fixed formats have a known winsRequired. Custom/unlimited are
  /// constructed via the named factories below.
  factory MatchFormatConfig.bestOf3() =>
      const MatchFormatConfig(format: MatchFormat.bestOf3, winsRequired: 2);

  factory MatchFormatConfig.bestOf5() =>
      const MatchFormatConfig(format: MatchFormat.bestOf5, winsRequired: 3);

  factory MatchFormatConfig.bestOf7() =>
      const MatchFormatConfig(format: MatchFormat.bestOf7, winsRequired: 4);

  factory MatchFormatConfig.bestOf9() =>
      const MatchFormatConfig(format: MatchFormat.bestOf9, winsRequired: 5);

  /// Custom requires a player-selected value; validated separately in T26.
  factory MatchFormatConfig.custom(int winsRequired) => MatchFormatConfig(
        format: MatchFormat.custom,
        winsRequired: winsRequired,
      );

  factory MatchFormatConfig.unlimited() =>
      const MatchFormatConfig(format: MatchFormat.unlimited, winsRequired: 0);

  /// Validates a custom wins-required value.
  /// Returns null if valid, or an error message ('INVALID VALUE') if not.
  static String? validateCustomWins(int? value) {
    if (value == null || value < minCustomWins || value > maxCustomWins) {
      return 'INVALID VALUE';
    }
    return null;
  }

  /// Standard match ends when any player reaches winsRequired.
  /// Unlimited has no automatic win threshold — always false.
  bool isMatchWon(int playerScore) {
    if (format == MatchFormat.unlimited) return false;
    return playerScore >= winsRequired;
  }

  bool get isUnlimited => format == MatchFormat.unlimited;

  /// Human-readable match-format label used by the in-game HUD,
  /// e.g. "Best of 3", "Custom (First to 5)", "Unlimited".
  String get displayLabel {
    switch (format) {
      case MatchFormat.bestOf3:
        return 'Best of 3';
      case MatchFormat.bestOf5:
        return 'Best of 5';
      case MatchFormat.bestOf7:
        return 'Best of 7';
      case MatchFormat.bestOf9:
        return 'Best of 9';
      case MatchFormat.custom:
        return 'Custom (First to $winsRequired)';
      case MatchFormat.unlimited:
        return 'Unlimited';
    }
  }
}