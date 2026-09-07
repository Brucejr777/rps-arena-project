import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/local_scoreboard.dart';

class PassDeviceScreen extends StatelessWidget {
  final VoidCallback onReady;

  final bool showScoreboard;
  final int playerAScore;
  final int playerBScore;
  final int roundNumber;
  final int draws;

  /// Optional game-mode label, e.g. "Best of 3".
  final String? modeLabel;

  const PassDeviceScreen({
    super.key,
    required this.onReady,
    this.showScoreboard = false,
    this.playerAScore = 0,
    this.playerBScore = 0,
    this.roundNumber = 1,
    this.draws = 0,
    this.modeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showScoreboard) ...[
                LocalScoreboard(
                  playerAScore: playerAScore,
                  playerBScore: playerBScore,
                  roundNumber: roundNumber,
                  draws: draws,
                  modeLabel: modeLabel,
                  margin: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
              ] else if (modeLabel != null) ...[
                Text(
                  modeLabel!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'PLAYER 1 LOCKED',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.swap_horiz,
                color: AppColors.defaultAccent,
                size: 56,
              ),
              const SizedBox(height: 24),
              const Text(
                'PASS THE DEVICE',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReady,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'READY',
                    style: TextStyle(
                      color: Colors.white,
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