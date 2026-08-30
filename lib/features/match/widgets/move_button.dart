import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/audio_service.dart';

class MoveButton extends StatelessWidget {
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
    onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        // selected button scales to 110%
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Opacity(
          // other two buttons disable (visually dimmed when disabled)
          opacity: isDisabled && !isSelected ? 0.35 : 1.0,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              // selected button receives current app accent
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
      ),
    );
  }
}