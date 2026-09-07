import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable scoreboard for local 2-player matches.
///
/// Shows:
/// - Player 1 score
/// - Player 2 score
/// - Current round
/// - Draw count when greater than zero
class LocalScoreboard extends StatelessWidget {
  final int playerAScore;
  final int playerBScore;
  final int roundNumber;
  final int draws;
  final EdgeInsetsGeometry margin;

  const LocalScoreboard({
    super.key,
    required this.playerAScore,
    required this.playerBScore,
    this.roundNumber = 1,
    this.draws = 0,
    this.margin = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: 1.5,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _scoreSide(
                  label: 'PLAYER 1',
                  score: playerAScore,
                  color: AppColors.blue,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _scoreSide(
                  label: 'PLAYER 2',
                  score: playerBScore,
                  color: AppColors.purple,
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ROUND $roundNumber',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (draws > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'DRAWS $draws',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreSide({
    required String label,
    required int score,
    required Color color,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}