import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../settings_repository.dart';
import '../../../core/services/audio_service.dart';

class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    setState(() => _settings = settings);
  }

  Future<void> _update(AppSettings updated) async {
    setState(() => _settings = updated);
    await _repository.save(updated);
    await AudioService.instance.refreshVolumesFromSettings();
  }

  Widget _volumeSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.defaultAccent,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.defaultAccent,
              overlayColor: AppColors.defaultAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.primaryText, fontWeight: FontWeight.bold)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.defaultAccent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

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
                    'AUDIO',
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
              if (settings == null)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.defaultAccent,
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _volumeSlider(
                          'MASTER VOLUME',
                          settings.masterVolume,
                          (v) => _update(settings.copyWith(masterVolume: v)),
                        ),
                        _volumeSlider(
                          'MUSIC',
                          settings.musicVolume,
                          (v) => _update(settings.copyWith(musicVolume: v)),
                        ),
                        _volumeSlider(
                          'SOUND EFFECTS',
                          settings.soundEffectsVolume,
                          (v) =>
                              _update(settings.copyWith(soundEffectsVolume: v)),
                        ),
                        const SizedBox(height: 8),
                        _toggleRow(
                          'VIBRATION',
                          settings.vibrationEnabled,
                          (v) => _update(settings.copyWith(vibrationEnabled: v)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}