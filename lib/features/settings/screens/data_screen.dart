import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../stats/local_stats_repository.dart';
import '../widgets/confirm_reset_dialog.dart';
import '../settings_repository.dart';
import '../../../core/widgets/mode_card.dart';

class DataScreen extends StatelessWidget {
  final VoidCallback onViewStatistics;
  final VoidCallback onResetLocalStatistics;
  final VoidCallback onResetSettings;

  const DataScreen({
    super.key,
    required this.onViewStatistics,
    required this.onResetLocalStatistics,
    required this.onResetSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
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
                      'DATA',
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
            const SizedBox(height: 16),

            // ── Data Cards ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  children: [
                    ModeCard(
                      iconAsset: 'assets/icons/icon_trophy.svg',
                      title: 'VIEW STATISTICS',
                      subtitle: 'See your gameplay stats',
                      iconColor: AppColors.svgGreen,
                      onTap: onViewStatistics,
                    ),
                    const SizedBox(height: 12),
                    ModeCard(
                      iconAsset: 'assets/icons/icon_settings.svg',
                      title: 'RESET LOCAL STATISTICS',
                      subtitle: 'Clear offline gameplay data',
                      badgeLabel: 'DANGER',
                      badgeColor: AppColors.red,
                      iconColor: AppColors.red,
                      onTap: () => ConfirmResetDialog.show(
                        context,
                        title: 'RESET LOCAL STATISTICS?',
                        message: 'This clears your offline gameplay statistics. Online competitive statistics are not affected.',
                        onConfirm: () async {
                          await LocalStatsRepository().resetLocalStatistics();
                          onResetLocalStatistics();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ModeCard(
                      iconAsset: 'assets/icons/icon_gamepad.svg',
                      title: 'RESET SETTINGS',
                      subtitle: 'Restore all defaults',
                      badgeLabel: 'DANGER',
                      badgeColor: AppColors.red,
                      iconColor: AppColors.red,
                      onTap: () => ConfirmResetDialog.show(
                        context,
                        title: 'RESET SETTINGS?',
                        message: 'This restores all appearance, audio, and gameplay settings to their defaults.',
                        onConfirm: () async {
                          await SettingsRepository().resetToDefaults();
                          onResetSettings();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

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