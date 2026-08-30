import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StandardGameplayScreen extends StatefulWidget {
  const StandardGameplayScreen({super.key});

  @override
  State<StandardGameplayScreen> createState() =>
      _StandardGameplayScreenState();
}

class _StandardGameplayScreenState extends State<StandardGameplayScreen> {
  // Placeholder state — will be replaced by MatchEngine/Riverpod in T11-T18
  int player1Score = 0;
  int player2Score = 0;
  int currentRound = 1;
  int selectionTimer = 10;
  String? selectedMove;

  void _selectMove(String move) {
    setState(() {
      selectedMove = move;
    });
  }

  Widget _handImage(String? move, {required bool isPlayer}) {
    final asset = move == null
        ? 'assets/images/placeholders/placeholder_rock.png' // neutral placeholder
        : 'assets/images/placeholders/placeholder_$move.png';
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }

  Widget _moveButton(String move, IconData icon) {
    final isSelected = selectedMove == move;
    return GestureDetector(
      onTap: selectedMove == null ? () => _selectMove(move) : null,
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColors.accentGradient(AppColors.defaultAccent)
                : null,
            color: isSelected ? null : AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.defaultAccent.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top row: exit control + round indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      // Pause-exit overlay comes in T10A
                    },
                  ),
                  Text(
                    'ROUND $currentRound',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 48), // balance the row
                ],
              ),
              const SizedBox(height: 12),

              // Player names + scores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _playerScoreCard('Player 1', player1Score),
                  Column(
                    children: [
                      Text(
                        '$selectionTimer',
                        style: TextStyle(
                          color: selectionTimer <= 5
                              ? AppColors.red
                              : AppColors.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _playerScoreCard('Player 2', player2Score),
                ],
              ),

              const Spacer(),

              // Hands
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _handImage(selectedMove, isPlayer: true),
                  Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  _handImage(null, isPlayer: false), // hidden until reveal
                ],
              ),

              const Spacer(),

              // Move buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _moveButton('rock', Icons.circle),
                  _moveButton('paper', Icons.square),
                  _moveButton('scissors', Icons.content_cut),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerScoreCard(String name, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(name,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}