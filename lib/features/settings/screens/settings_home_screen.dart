import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SettingsHomeScreen extends StatelessWidget {
  final VoidCallback onAppearance;
  final VoidCallback onAudio;
  final VoidCallback onGameplay;
  final VoidCallback onData;

  const SettingsHomeScreen({
    super.key,
    required this.onAppearance,
    required this.onAudio,
    required this.onGameplay,
    required this.onData,
  });

  Widget _settingsOption(String label, VoidCallback onTap) {
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
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
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
                    'SETTINGS',
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
              _settingsOption('APPEARANCE', onAppearance),
              _settingsOption('AUDIO', onAudio),
              _settingsOption('GAMEPLAY', onGameplay),
              _settingsOption('DATA', onData),
            ],
          ),
        ),
      ),
    );
  }
}