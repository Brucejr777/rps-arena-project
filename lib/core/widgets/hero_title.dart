import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wireframe hero title: "RPS" in white with a blue glow, "ARENA" in purple
/// with a purple glow (matches 02-MainMenuScreenHeroTitle.svg: two text
/// paths, fill white + fill #7C3AED, drop-shadow filter).
class HeroTitle extends StatelessWidget {
  final String first;
  final String second;
  final double fontSize;

  const HeroTitle({
    super.key,
    required this.first,
    required this.second,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
        children: [
          TextSpan(
            text: first,
            style: const TextStyle(
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0x882563EB),
                  blurRadius: 7.5,
                ),
              ],
            ),
          ),
          TextSpan(
            text: second,
            style: TextStyle(
              color: AppColors.purple,
              shadows: [
                Shadow(
                  color: AppColors.purple.withValues(alpha: 0.55),
                  blurRadius: 7.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "GAME MODE" section header: line — text — line (blue / purple),
/// matching the wireframe hero-title layout.
class GameModeHeader extends StatelessWidget {
  const GameModeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'GAME MODE',
          style: TextStyle(
            color: AppColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}