import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/match_format.dart';

class MatchFormatSelectScreen extends StatelessWidget {
  const MatchFormatSelectScreen({super.key});

  static const _options = <(String, MatchFormat, String, Color, String, Color)>[
    ('BEST OF 3', MatchFormat.bestOf3, 'assets/icons/icon_bolt.svg', AppColors.svgGreen, 'READY', AppColors.badgeGreen),
    ('BEST OF 5', MatchFormat.bestOf5, 'assets/icons/icon_settings.svg', AppColors.svgCyan, '7 ROUNDS', AppColors.svgCyan),
    ('BEST OF 7', MatchFormat.bestOf7, 'assets/icons/icon_timer.svg', AppColors.svgOrange, '9 ROUNDS', AppColors.svgOrange),
    ('BEST OF 9', MatchFormat.bestOf9, 'assets/icons/icon_gamepad.svg', AppColors.svgRed, '11 ROUNDS', AppColors.svgRed),
    ('CUSTOM', MatchFormat.custom, 'assets/icons/icon_settings.svg', AppColors.svgPink, 'YOUR RULES', AppColors.svgPink),
    ('UNLIMITED', MatchFormat.unlimited, 'assets/icons/icon_rocket.svg', AppColors.svgMagenta, 'ENDLESS', AppColors.svgMagenta),
  ];

  MatchFormatConfig _configFor(MatchFormat format) {
    switch (format) {
      case MatchFormat.bestOf3:
        return MatchFormatConfig.bestOf3();
      case MatchFormat.bestOf5:
        return MatchFormatConfig.bestOf5();
      case MatchFormat.bestOf7:
        return MatchFormatConfig.bestOf7();
      case MatchFormat.bestOf9:
        return MatchFormatConfig.bestOf9();
      case MatchFormat.custom:
        return MatchFormatConfig.custom(0);
      case MatchFormat.unlimited:
        return MatchFormatConfig.unlimited();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'MATCH LENGTH',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final (label, format, iconPath, iconColor, badgeText, badgeColor) = _options[index];
                    return _FormatCard(
                      label: label,
                      iconPath: iconPath,
                      iconColor: iconColor,
                      badgeText: badgeText,
                      badgeColor: badgeColor,
                      onTap: () {
                        Navigator.of(context).pop(_configFor(format));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _FormatCard({
    required this.label,
    required this.iconPath,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.blue.withValues(alpha: 0.5),
                AppColors.purple.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 54.5,
                  height: 54.5,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(11.25),
                    border: Border.all(
                      width: 1.5,
                      color: iconColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconPath,
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
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
