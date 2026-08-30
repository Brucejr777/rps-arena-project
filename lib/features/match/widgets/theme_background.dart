import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum GameTheme { normal, space }

class ThemeBackground extends StatelessWidget {
  final GameTheme theme;
  final Widget child;

  const ThemeBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (theme) {
      case GameTheme.normal:
        return Container(
          decoration: const BoxDecoration(
            // Normal theme: clean arena background, subtle gradient,
            // minimal particles/elements (kept intentionally simple
            // so gameplay stays the visual focus).
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, Color(0xFF162238)],
            ),
          ),
          child: child,
        );
      case GameTheme.space:
        // T54 builds the Space theme version of this.
        return Container(
          color: AppColors.background,
          child: child,
        );
    }
  }
}