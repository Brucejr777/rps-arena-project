import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../settings_repository.dart';

class GameplaySettingsScreen extends StatefulWidget {
  const GameplaySettingsScreen({super.key});

  @override
  State<GameplaySettingsScreen> createState() =>
      _GameplaySettingsScreenState();
}

class _GameplaySettingsScreenState extends State<GameplaySettingsScreen> {
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
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 13)),
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
                    'GAMEPLAY',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
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
                        _sectionLabel('Animation Speed'),
                        Row(
                          children: [
                            Expanded(
                              child: _speedOption(
                                'FULL',
                                settings.animationSpeed == AnimationSpeed.full,
                                () => _update(settings.copyWith(
                                    animationSpeed: AnimationSpeed.full)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _speedOption(
                                'FAST',
                                settings.animationSpeed == AnimationSpeed.fast,
                                () => _update(settings.copyWith(
                                    animationSpeed: AnimationSpeed.fast)),
                              ),
                            ),
                          ],
                        ),
                        _sectionLabel('Victory Animations'),
                        _toggleRow(
                          settings.victoryAnimationsEnabled,
                          (value) => _update(settings.copyWith(
                              victoryAnimationsEnabled: value)),
                        ),
                        _sectionLabel('Vibration'),
                        _toggleRow(
                          settings.vibrationEnabled,
                          (value) => _update(
                              settings.copyWith(vibrationEnabled: value)),
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

  Widget _speedOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient:
              isSelected ? AppColors.accentGradient(AppColors.defaultAccent) : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value ? 'ON' : 'OFF',
            style: TextStyle(
              color: value ? AppColors.green : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.defaultAccent,
          ),
        ],
      ),
    );
  }
}