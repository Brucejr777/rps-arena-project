import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A card matching the Figma wireframe design:
/// - #1E293B fill with 16px border radius
/// - 1px gradient stroke from blue to purple accent
/// - Optional inner icon container
class GradientCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? borderRadius;
  final EdgeInsets? padding;
  final bool showIconContainer;
  final IconData? icon;
  final double? width;
  final double? height;

  const GradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding,
    this.showIconContainer = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius!),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blue.withValues(alpha: 0.3),
                AppColors.purple.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(borderRadius! - 1),
            ),
            child: showIconContainer
                ? _buildWithIconContainer()
                : Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithIconContainer() {
    return Row(
      children: [
        const SizedBox(width: 16),
        // Icon container
        Container(
          width: 54.5,
          height: 54.5,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(11.25),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.defaultAccent,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            child: child,
          ),
        ),
      ],
    );
  }
}
