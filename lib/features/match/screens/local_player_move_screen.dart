import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/move_button.dart';

class LocalPlayerMoveScreen extends StatefulWidget {
  final int playerNumber; // 1 or 2
  final void Function(String move) onMoveSelected;

  const LocalPlayerMoveScreen({
    super.key,
    required this.playerNumber,
    required this.onMoveSelected,
  });

  @override
  State<LocalPlayerMoveScreen> createState() => _LocalPlayerMoveScreenState();
}

class _LocalPlayerMoveScreenState extends State<LocalPlayerMoveScreen> {
  String? _selectedMove;

  void _select(String move) {
    if (_selectedMove != null) return; // T41: selection cannot change
    setState(() => _selectedMove = move);
    widget.onMoveSelected(move);
  }

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
              const Text(
                'Make your choice.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 48),
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