import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/match_controller.dart';
import '../../online/screens/connection_lost_screen.dart';
import 'pause_exit_overlay.dart';
import 'move_button.dart';

class UnlimitedGameplayScreen extends ConsumerStatefulWidget {
  const UnlimitedGameplayScreen({super.key});

  @override
  ConsumerState<UnlimitedGameplayScreen> createState() =>
      _UnlimitedGameplayScreenState();
}

class _UnlimitedGameplayScreenState
    extends ConsumerState<UnlimitedGameplayScreen> {
  final MatchMode mode = MatchMode.offline; // TODO: pass in from setup screen

  int player1Score = 0;
  int player2Score = 0;
  int roundsPlayed = 0;
  int draws = 0;
  int selectionTimer = 10;
  String? selectedMove;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).setMode(mode);
    });
  }

  void _selectMove(String move) {
    setState(() {
      selectedMove = move;
    });
  }

  Widget _handImage(String? move) {
    final asset = move == null
        ? 'assets/images/placeholders/placeholder_rock.png'
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

  void _onExitPressed() {
    ref.read(matchControllerProvider.notifier).pause();
    setState(() => isPaused = true);
  }

  void _onResume() {
    ref.read(matchControllerProvider.notifier).resume();
    setState(() => isPaused = false);
  }

  void _onExitConfirmed() {
    final outcome = ref.read(matchControllerProvider.notifier).attemptExit();
    setState(() => isPaused = false);

    switch (outcome) {
      case ExitOutcome.connectionLost:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConnectionLostScreen()),
        );
        break;
      case ExitOutcome.rankedQuitLoss:
        Navigator.of(context).maybePop();
        break;
      case ExitOutcome.exitedCleanly:
      case ExitOutcome.resumed:
        Navigator.of(context).maybePop();
        break;
    }
  }

  void _onEndMatchPressed() {
    showDialog(
      context: context,
      builder: (_) => _EndMatchDialog(
        player1Score: player1Score,
        player2Score: player2Score,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () {
          Navigator.of(context).pop(); // close dialog
          // TODO T27/T28: finalize Unlimited result and navigate to
          // UnlimitedResultScreen once it exists (T30).
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: _onExitPressed,
                      ),
                      Column(
                        children: [
                          Text(
                            'ROUNDS PLAYED: $roundsPlayed',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'DRAWS: $draws',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed:
                            roundsPlayed > 0 ? _onEndMatchPressed : null,
                        child: Text(
                          'END MATCH',
                          style: TextStyle(
                            color: roundsPlayed > 0
                                ? AppColors.red
                                : Colors.white24,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _playerScoreCard('Player 1', player1Score),
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
                      _playerScoreCard('Player 2', player2Score),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _handImage(selectedMove),
                      Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      _handImage(null),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MoveButton(
                        move: 'rock',
                        icon: Icons.circle,
                        isSelected: selectedMove == 'rock',
                        isDisabled: selectedMove != null,
                        onSelected: () => _selectMove('rock'),
                      ),
                      MoveButton(
                        move: 'paper',
                        icon: Icons.square,
                        isSelected: selectedMove == 'paper',
                        isDisabled: selectedMove != null,
                        onSelected: () => _selectMove('paper'),
                      ),
                      MoveButton(
                        move: 'scissors',
                        icon: Icons.content_cut,
                        isSelected: selectedMove == 'scissors',
                        isDisabled: selectedMove != null,
                        onSelected: () => _selectMove('scissors'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (isPaused)
              PauseExitOverlay(onResume: _onResume, onExit: _onExitConfirmed),
          ],
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

class _EndMatchDialog extends StatelessWidget {
  final int player1Score;
  final int player2Score;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _EndMatchDialog({
    required this.player1Score,
    required this.player2Score,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'END MATCH?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Current Score: $player1Score - $player2Score',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CANCEL',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('END MATCH',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}