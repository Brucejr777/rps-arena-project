import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../stats/local_stats_repository.dart';
import '../widgets/confirm_reset_dialog.dart';
import '../settings_repository.dart';

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

  Widget _dataOption(String label, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: danger ? AppColors.red : AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Icon(Icons.chevron_right,
                  color: danger ? AppColors.red : Colors.white38),
            ],
          ),
        ),
      ),
    );
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'DATA',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _dataOption('VIEW STATISTICS', onViewStatistics),
              _dataOption(
                'RESET LOCAL STATISTICS',
                () => ConfirmResetDialog.show(
                  context,
                  title: 'RESET LOCAL STATISTICS?',
                  message:
                      'This clears your offline gameplay statistics. Online competitive statistics are not affected.',
                  onConfirm: () async {
                    await LocalStatsRepository().resetLocalStatistics();
                    onResetLocalStatistics(); // notify parent (e.g. show a snackbar, refresh UI)
                  },
                ),
                danger: true,
              ),
              _dataOption(
                'RESET SETTINGS',
                () => ConfirmResetDialog.show(
                  context,
                  title: 'RESET SETTINGS?',
                  message:
                      'This restores all appearance, audio, and gameplay settings to their defaults.',
                  onConfirm: () async {
                    await SettingsRepository().resetToDefaults();
                    onResetSettings(); // notify parent (e.g. show a snackbar, refresh UI)
                  },
                ),
                danger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}