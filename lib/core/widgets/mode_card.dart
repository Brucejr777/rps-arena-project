import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// A mode selection card matching the wireframe design:
/// - Gradient border (blue to purple)
/// - Surface fill
/// - Inner icon container (54.5x54.5 rounded square)
/// - Title text + subtitle
/// - Optional badge (e.g. "COMING SOON", "ACCOUNT REQUIRED")
class ModeCard extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String title;
  final String? subtitle;
  final String? subtitle2;
  final String? badgeLabel;
  final Color? badgeColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? trailing;

  const ModeCard({
    super.key,
    this.icon,
    this.iconAsset,
    required this.title,
    this.subtitle,
    this.subtitle2,
    this.badgeLabel,
    this.badgeColor,
    this.iconColor,
    this.onTap,
    this.enabled = true,
    this.trailing,
  }) : assert(icon != null || iconAsset != null, 'Either icon or iconAsset must be provided');

  @override
  Widget build(BuildContext context) {
    final cardOpacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: cardOpacity,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.blue.withValues(alpha: enabled ? 0.5 : 0.2),
                  AppColors.purple.withValues(alpha: enabled ? 0.5 : 0.2),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon container — wireframe: #0F172A fill + gradient stroke
                  Container(
                    width: 54.5,
                    height: 54.5,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(11.25),
                      border: Border.all(
                        width: 1.5,
                        color: enabled
                            ? (iconColor ?? AppColors.blue).withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: iconAsset != null
                          ? SvgPicture.asset(
                              iconAsset!,
                              width: 26,
                              height: 26,
                              colorFilter: ColorFilter.mode(
                                enabled
                                    ? (iconColor ?? AppColors.defaultAccent)
                                    : Colors.white24,
                                BlendMode.srcIn,
                              ),
                            )
                          : Icon(
                              icon!,
                              color: enabled
                                  ? (iconColor ?? AppColors.defaultAccent)
                                  : Colors.white24,
                              size: 26,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: enabled
                                ? AppColors.primaryText
                                : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: enabled
                                  ? Colors.white54
                                  : Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (subtitle2 != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle2!,
                            style: TextStyle(
                              color: enabled
                                  ? Colors.white38
                                  : Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Badge (top-aligned)
                  if (badgeLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  // Chevron-right (always shown when enabled, per wireframe)
                  if (enabled) ...[
                    if (badgeLabel == null) const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF94A3B8), size: 20),
                  ],
                  // Trailing widget (overrides chevron when present)
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
