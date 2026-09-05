import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../settings_repository.dart';

class SettingsHomeScreen extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends ConsumerState<SettingsHomeScreen> {
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsRepository().load();
    if (mounted) setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    final themeName = s?.theme ?? 'Default Dark';
    final volume = s == null
        ? null
        : ((s.masterVolume * s.soundEffectsVolume) * 100).round();
    final animLabel = switch (s?.animationSpeed) {
      AnimationSpeed.fast => 'Fast',
      AnimationSpeed.full => 'Full',
      null => 'Full',
    };
    final vibration = s?.vibrationEnabled ?? true;

    // Match the wireframe drawer panel: right-aligned surface panel with a
    // glowing border, header, and category cards.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dimmed backdrop (matches the drawer overlay feel)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
          // Right-side settings panel
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 300,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(
                  width: 1.5,
                  color: const Color(0xFF06B6D4),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Panel header ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'SETTINGS',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white54,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Category cards ───────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _SettingsCard(
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            desc: 'Custom Theme, UI Colors',
                            value: 'Current: $themeName',
                            onTap: widget.onAppearance,
                          ),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            icon: Icons.music_note_outlined,
                            title: 'Audio',
                            desc: 'Music, Sound Effects',
                            value: volume == null ? '' : 'Volume: $volume%',
                            onTap: widget.onAudio,
                          ),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            icon: Icons.sports_esports_outlined,
                            title: 'Gameplay',
                            desc: 'Animations, Haptics',
                            value: 'Speed: $animLabel · Vibration: ${vibration ? 'On' : 'Off'}',
                            onTap: widget.onGameplay,
                          ),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            icon: Icons.cloud_outlined,
                            title: 'Data',
                            desc: 'Statistics, Cloud Save',
                            value: 'Synced',
                            onTap: widget.onData,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category card matching the wireframe settings drawer: icon container,
/// title, description line, and current-value line.
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String value;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blue.withValues(alpha: 0.5),
              AppColors.purple.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 1.5,
                    color: AppColors.blue,
                  ),
                ),
                child: Icon(icon, color: Colors.white70, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}