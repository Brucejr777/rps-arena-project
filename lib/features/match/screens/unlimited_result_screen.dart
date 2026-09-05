import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class UnlimitedResultScreen extends StatelessWidget {
  final int player1Wins;
  final int player2Wins;
  final int draws;
  final int totalRounds;
  final double player1WinRate;
  final double player2WinRate;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const UnlimitedResultScreen({
    super.key,
    required this.player1Wins,
    required this.player2Wins,
    required this.draws,
    required this.totalRounds,
    required this.player1WinRate,
    required this.player2WinRate,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'MATCH SUMMARY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _statRow('PLAYER 1 wins', '$player1Wins'),
                    _statRow('PLAYER 2 wins', '$player2Wins'),
                    _statRow('Draws', '$draws'),
                    const Divider(color: Colors.white24, height: 24),
                    _statRow('TOTAL ROUNDS', '$totalRounds'),
                    _statRow('PLAYER 1 WIN RATE',
                        '${player1WinRate.toStringAsFixed(1)}%'),
                    _statRow('PLAYER 2 WIN RATE',
                        '${player2WinRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
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
              const SizedBox(height: 12),
              OutlinedButton(
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
            ],
          ),
        ),
      ),
    );
  }
}