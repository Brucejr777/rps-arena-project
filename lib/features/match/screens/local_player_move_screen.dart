import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/local_scoreboard.dart';

/// Colors per gesture card, taken from wireframes 09A/09B:
/// rock -> orange, paper -> cyan, scissors -> pink.
const _rockBorder = Color(0xFFF97316);
const _rockDark = Color(0xFF7C2D12);
const _paperBorder = Color(0xFF06B6D4);
const _paperDark = Color(0xFF164E63);
const _scissorsBorder = Color(0xFFEC4899);
const _scissorsDark = Color(0xFF831843);

class LocalPlayerMoveScreen extends ConsumerStatefulWidget {
  final int playerNumber;
  final void Function(String move) onMoveSelected;
  final bool showScoreboard;
  final int playerAScore;
  final int playerBScore;
  final int roundNumber;
  final int draws;
  final String? modeLabel;

  const LocalPlayerMoveScreen({
    super.key,
    required this.playerNumber,
    required this.onMoveSelected,
    this.showScoreboard = false,
    this.playerAScore = 0,
    this.playerBScore = 0,
    this.roundNumber = 1,
    this.draws = 0,
    this.modeLabel,
  });

  @override
  ConsumerState<LocalPlayerMoveScreen> createState() =>
      _LocalPlayerMoveScreenState();
}

class _LocalPlayerMoveScreenState extends ConsumerState<LocalPlayerMoveScreen> {
  String? _selectedMove;

  void _select(String move) {
    if (_selectedMove != null) return;
    // Link the select mp3 to the gesture selection.
    AudioService.instance.playSelect();
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
        child: Column(
          children: [
            _buildTopNav(),
            if (widget.showScoreboard) ...[
              const SizedBox(height: 12),
              LocalScoreboard(
                playerAScore: widget.playerAScore,
                playerBScore: widget.playerBScore,
                roundNumber: widget.roundNumber,
                draws: widget.draws,
                modeLabel: widget.modeLabel,
              ),
              const SizedBox(height: 8),
            ] else ...[
              const SizedBox(height: 12),
              if (widget.modeLabel != null)
                Text(
                  widget.modeLabel!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            // ── Hero title ─────────────────────────────────────────
            Text(
              'PLAYER ${widget.playerNumber}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedMove == null ? 'Make your choice.' : 'LOCKED',
              style: TextStyle(
                color: _selectedMove == null
                    ? AppColors.blue
                    : AppColors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            // ── Gesture cards ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GestureCard(
                    move: 'rock',
                    label: 'ROCK',
                    borderColor: _rockBorder,
                    labelColor: _rockDark,
                    isSelected: _selectedMove == 'rock',
                    isDisabled:
                        _selectedMove != null && _selectedMove != 'rock',
                    handAsset: themeController.handAssetFor('rock'),
                    onTap: () => _select('rock'),
                  ),
                  _GestureCard(
                    move: 'paper',
                    label: 'PAPER',
                    borderColor: _paperBorder,
                    labelColor: _paperDark,
                    isSelected: _selectedMove == 'paper',
                    isDisabled:
                        _selectedMove != null && _selectedMove != 'paper',
                    handAsset: themeController.handAssetFor('paper'),
                    onTap: () => _select('paper'),
                  ),
                  _GestureCard(
                    move: 'scissors',
                    label: 'SCISSORS',
                    borderColor: _scissorsBorder,
                    labelColor: _scissorsDark,
                    isSelected: _selectedMove == 'scissors',
                    isDisabled: _selectedMove != null &&
                        _selectedMove != 'scissors',
                    handAsset: themeController.handAssetFor('scissors'),
                    onTap: () => _select('scissors'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // ── Bottom frame indicator ─────────────────────────────
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: AppColors.blue,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'PLAYER ${widget.playerNumber}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// A gesture selection card matching the wireframe:
/// colored rounded border, circular hand image, move label below.
class _GestureCard extends StatelessWidget {
  final String move;
  final String label;
  final Color borderColor;
  final Color labelColor;
  final bool isSelected;
  final bool isDisabled;
  final String handAsset;
  final VoidCallback onTap;

  const _GestureCard({
    required this.move,
    required this.label,
    required this.borderColor,
    required this.labelColor,
    required this.isSelected,
    required this.isDisabled,
    required this.handAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected ? AppColors.green : borderColor;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Opacity(
          opacity: isDisabled ? 0.35 : 1.0,
          child: Container(
            width: 112,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(19.5),
              border: Border.all(
                width: 1.5,
                color: border,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: border.withValues(alpha: 0.45),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1.5,
                      color: isSelected ? AppColors.green : labelColor,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    handAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.green : labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}