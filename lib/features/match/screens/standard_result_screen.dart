import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StandardResultScreen extends StatelessWidget {
  final bool playerWon;
  final int playerScore;
  final int opponentScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  /// T122: Optional rating fields for ranked matches.
  final int? ratingBefore;
  final int? ratingAfter;

  /// Optional override for the result title.
  ///
  /// For single-player mode this can remain null, showing VICTORY/DEFEAT.
  /// For local 2-player mode this should be:
  /// - PLAYER 1 WON
  /// - PLAYER 2 WON
  /// - DRAW
  final String? resultTitle;

  /// Optional override for the result color.
  final Color? resultColor;

  /// Whether the single-player "MATCH WON" badge should be shown.
  ///
  /// This should be false for local 2-player matches.
  final bool showMatchWon;

  const StandardResultScreen({
    super.key,
    required this.playerWon,
    required this.playerScore,
    required this.opponentScore,
    required this.onPlayAgain,
    required this.onMainMenu,
    this.ratingBefore,
    this.ratingAfter,
    this.resultTitle,
    this.resultColor,
    this.showMatchWon = true,
  });

  @override
  Widget build(BuildContext context) {
    final String title = resultTitle ?? (playerWon ? 'VICTORY' : 'DEFEAT');
    final Color color =
        resultColor ?? (playerWon ? AppColors.green : AppColors.red);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Result Card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1.5,
                    color: color.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$playerScore - $opponentScore',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (playerWon && showMatchWon) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MATCH WON',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── T122: Rating change for ranked matches ─────
              if (ratingBefore != null && ratingAfter != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'RATING',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$ratingBefore',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                          Text(
                            '$ratingAfter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final diff = ratingAfter! - ratingBefore!;
                              if (diff == 0) return const SizedBox.shrink();

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (diff > 0
                                          ? AppColors.green
                                          : AppColors.red)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  diff > 0 ? '+$diff' : '$diff',
                                  style: TextStyle(
                                    color: diff > 0
                                        ? AppColors.green
                                        : AppColors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPlayAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onMainMenu,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'MAIN MENU',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}