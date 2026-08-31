import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';

class MoveButton extends ConsumerWidget {
  final String move; // 'rock', 'paper', 'scissors'
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onSelected;

  const MoveButton({
    super.key,
    required this.move,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.onSelected,
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.accentGradient(accent) : null,
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
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}