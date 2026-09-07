import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hero_title.dart';
import '../../../core/widgets/mode_card.dart';

class MultiplayerScreen extends StatelessWidget {
  final VoidCallback onQuickMatch;
  final VoidCallback onPrivateRoom;
  final VoidCallback onRankedMatch;
  final VoidCallback onSettings;

  const MultiplayerScreen({
    super.key,
    required this.onQuickMatch,
    required this.onPrivateRoom,
    required this.onRankedMatch,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top nav: back + settings gear ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.settings,
                    onTap: onSettings,
                    isSettings: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Hero title ─────────────────────────────────────
            const HeroTitle(first: 'MULTI', second: 'PLAYER', fontSize: 30),
            const SizedBox(height: 14),
            const GameModeHeader(),
            const SizedBox(height: 28),

            // ── Mode cards (wireframe copy + colored badges) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ModeCard(
                    iconAsset: 'assets/icons/icon_bolt.svg',
                    title: 'Quick Match',
                    subtitle:
                        'Instantly connect and battle random players worldwide.',
                    badgeLabel: 'CASUAL',
                    badgeColor: AppColors.badgeGreen,
                    iconColor: AppColors.svgGreen,
                    onTap: onQuickMatch,
                  ),
                  const SizedBox(height: 12),
                  ModeCard(
                    iconAsset: 'assets/icons/icon_gamepad.svg', // ← CHANGED: was icon_settings.svg
                    title: 'Private Room',
                    subtitle:
                        'Create or join a room with a code for your friends',
                    badgeLabel: 'FRIENDS',
                    badgeColor: AppColors.svgCyan,
                    iconColor: AppColors.svgCyan,
                    onTap: onPrivateRoom,
                  ),
                  const SizedBox(height: 12),
                  ModeCard(
                    iconAsset: 'assets/icons/icon_trophy.svg',
                    title: 'Ranked Match',
                    subtitle: 'Compete for leaderboard rank and points.',
                    badgeLabel: 'EXPERT',
                    badgeColor: AppColors.badgeOrange,
                    iconColor: AppColors.svgOrange,
                    onTap: onRankedMatch,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Bottom Frame Indicator ─────────────────────────
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular icon button matching the wireframe top nav.
/// Back button: blue border + glow. Settings gear: #334155 border, no glow.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isSettings;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.isSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSettings ? 39.0 : 40.0,
        height: isSettings ? 39.0 : 40.0,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            width: 1.5,
            color: isSettings
                ? const Color(0xFF334155)
                : AppColors.blue,
          ),
          boxShadow: isSettings
              ? []
              : [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}