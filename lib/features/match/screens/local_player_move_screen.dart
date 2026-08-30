import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../widgets/move_button.dart';

class LocalPlayerMoveScreen extends ConsumerStatefulWidget {
  final int playerNumber;
  final void Function(String move) onMoveSelected;

  const LocalPlayerMoveScreen({
    super.key,
    required this.playerNumber,
    required this.onMoveSelected,
  });

  @override
  ConsumerState<LocalPlayerMoveScreen> createState() =>
      _LocalPlayerMoveScreenState();
}

class _LocalPlayerMoveScreenState extends ConsumerState<LocalPlayerMoveScreen> {
  String? _selectedMove;

  void _select(String move) {
    if (_selectedMove != null) return;
    setState(() => _selectedMove = move);

    // Brief pause so the lock/scale animation and hand image are
    // actually visible before advancing to the next stage.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onMoveSelected(move);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(gameThemeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PLAYER ${widget.playerNumber}',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedMove == null ? 'Make your choice.' : 'LOCKED',
                style: TextStyle(
                  color: _selectedMove == null
                      ? Colors.white54
                      : AppColors.green,
                  fontSize: 14,
                  fontWeight:
                      _selectedMove == null ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Shows the selected hand once locked
              SizedBox(
                height: 100,
                child: _selectedMove == null
                    ? null
                    : Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          themeController.handAssetFor(_selectedMove!),
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MoveButton(
                    move: 'rock',
                    icon: Icons.circle,
                    isSelected: _selectedMove == 'rock',
                    isDisabled: _selectedMove != null,
                    onSelected: () => _select('rock'),
                  ),
                  MoveButton(
                    move: 'paper',
                    icon: Icons.square,
                    isSelected: _selectedMove == 'paper',
                    isDisabled: _selectedMove != null,
                    onSelected: () => _select('paper'),
                  ),
                  MoveButton(
                    move: 'scissors',
                    icon: Icons.content_cut,
                    isSelected: _selectedMove == 'scissors',
                    isDisabled: _selectedMove != null,
                    onSelected: () => _select('scissors'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}