import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rps_arena/features/match/widgets/theme_background.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/match_controller.dart';
import '../../online/screens/connection_lost_screen.dart';
import 'pause_exit_overlay.dart';
import 'move_button.dart';
import '../../../core/theme/game_theme_controller.dart';

class StandardGameplayScreen extends ConsumerStatefulWidget {
  const StandardGameplayScreen({super.key});

  @override
  ConsumerState<StandardGameplayScreen> createState() =>
      _StandardGameplayScreenState();
}

class _StandardGameplayScreenState
    extends ConsumerState<StandardGameplayScreen> {
  final MatchMode mode = MatchMode.offline; // TODO: pass in from setup screen

  int player1Score = 0;
  int player2Score = 0;
  int currentRound = 1;
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

  Widget _handImage(String? move, {required bool isPlayer}) {
    final themeController = ref.read(gameThemeProvider.notifier);
    final asset = move == null
      ? themeController.handAssetFor('rock') // neutral placeholder while hidden
      : themeController.handAssetFor(move);
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
        // TODO: send quit-loss result to server once online matches exist (T106)
        Navigator.of(context).maybePop();
        break;
      case ExitOutcome.exitedCleanly:
      case ExitOutcome.resumed:
        Navigator.of(context).maybePop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ThemeBackground(
        theme: ref.watch(gameThemeProvider),
        child: SafeArea(
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
                      Text(
                        'ROUND $currentRound',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      _handImage(null, isPlayer: false),
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
              PauseExitOverlay(
                onResume: _onResume,
                onExit: _onExitConfirmed,
              ),
          ],
        ),
      ),
    )
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