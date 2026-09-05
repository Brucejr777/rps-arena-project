import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';

class MoveButton extends ConsumerWidget {
  final String move; // 'rock', 'paper', 'scissors'
  final String iconAsset;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onSelected;
  final Color? frameColor;

  const MoveButton({
    super.key,
    required this.move,
    required this.iconAsset,
    required this.isSelected,
    required this.isDisabled,
    required this.onSelected,
    this.frameColor,
  });

  void _handleTap() {
    if (isDisabled) return;
    AudioService.instance.playSound('select');
    VibrationService.instance.selection();
    onSelected();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(appAccentColorProvider);

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
                  child: SvgPicture.asset(
                    iconAsset,
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  move.toUpperCase(),
                  style: TextStyle(
                    color: frameColor ?? Colors.white70,
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