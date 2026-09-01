import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Rank tier badge widget (T115).
///
/// Displays a styled badge for each rank tier:
/// - Bronze
/// - Silver
/// - Gold
/// - Platinum
/// - Diamond
/// - Master
class RankBadge extends StatelessWidget {
  final String rank;
  final double fontSize;
  final bool showIcon;

  const RankBadge({
    super.key,
    required this.rank,
    this.fontSize = 12,
    this.showIcon = true,
  });

  /// Get the color for a rank tier.
  static Color colorFor(String rank) {
    switch (rank) {
      case 'Master':
        return AppColors.purple;
      case 'Diamond':
        return const Color(0xFF06B6D4);
      case 'Platinum':
        return const Color(0xFF8B5CF6);
      case 'Gold':
        return const Color(0xFFF59E0B);
      case 'Silver':
        return const Color(0xFF94A3B8);
      case 'Bronze':
        return const Color(0xFFCD7F32);
      default:
        return Colors.white54;
    }
  }

  /// Get the icon for a rank tier.
  static IconData iconFor(String rank) {
    switch (rank) {
      case 'Master':
        return Icons.diamond; // or crown
      case 'Diamond':
        return Icons.diamond;
      case 'Platinum':
        return Icons.star;
      case 'Gold':
        return Icons.workspace_premium;
      case 'Silver':
        return Icons.shield;
      case 'Bronze':
        return Icons.emoji_events;
      default:
        return Icons.help_outline;
    }
  }

  /// Get the background color (with alpha) for a rank tier.
  static Color backgroundColorFor(String rank) {
    return colorFor(rank).withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(rank);
    final bgColor = backgroundColorFor(rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(iconFor(rank), size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            rank.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
