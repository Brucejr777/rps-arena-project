import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';

/// Move selection button used across all game modes.
///
/// Displays the themed hand image (PNG) matching the active Game Theme
/// (Normal / Space), consistent with LocalPlayerMoveScreen and all
/// single-player / local flows.
class MoveButton extends ConsumerWidget {
  final String move; // 'rock', 'paper', 'scissors'

  /// Kept for backward compatibility but no longer used for rendering.
  /// The themed PNG hand asset is resolved automatically via
  /// [gameThemeProvider].
  final String? iconAsset;

  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onSelected;
  final Color? frameColor;

  const MoveButton({
    super.key,
    required this.move,
    this.iconAsset, // deprecated — kept so existing call-sites compile
    required this.isSelected,
    required this.isDisabled,
    required this.onSelected,
    this.frameColor,
  });

  void _handleTap() {
    if (isDisabled) return;
    AudioService.instance.playSelect();
    VibrationService.instance.selection();
    onSelected();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(appAccentColorProvider);
    // Resolve the themed hand image (PNG) for the active Game Theme,
    // exactly matching LocalPlayerMoveScreen / SinglePlayerMatchFlowScreen.
    final themeController = ref.watch(gameThemeProvider.notifier);
    final handAsset = themeController.handAssetFor(move);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Opacity(
          opacity: isDisabled && !isSelected ? 0.35 : 1.0,
          child: Container(
            width: 112,
            height: 127,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19.5),
              border: frameColor != null
                  ? Border.all(color: frameColor!, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 69,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.accentGradient(accent)
                        : null,
                    color: isSelected ? null : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1.5,
                      color: isSelected
                          ? AppColors.green
                          : (frameColor ?? Colors.white24),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    handAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  move.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.green
                        : (frameColor ?? Colors.white70),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
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