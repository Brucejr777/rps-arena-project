import 'dart:math';
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, Color(0xFF162238)],
            ),
          ),
          child: child,
        );

      case GameTheme.space:
        return Stack(
          children: [
            // Dark space background with blue/purple lighting
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.4,
                  colors: [Color(0xFF1A1040), Color(0xFF05070F)],
                ),
              ),
            ),
            // Stars / energy particles
            Positioned.fill(
              child: CustomPaint(painter: _StarfieldPainter()),
            ),
            // Holographic accent glow near the top
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryAccent.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        );
    }
  }
}

/// Paints a simple deterministic starfield — fixed seed so stars don't
/// jump around between rebuilds.
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7); // fixed seed for a stable starfield
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    for (var i = 0; i < 80; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.4 + 0.3;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}