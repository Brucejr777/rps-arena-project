import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../settings_repository.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final SettingsRepository _repository = SettingsRepository();
  AppSettings? _settings;

  static const _appColors = ['Blue', 'Purple', 'Red', 'Green', 'Orange'];
  static const _themes = ['Normal', 'Space'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    setState(() => _settings = settings);
  }

  Future<void> _save() async {
    if (_settings == null) return;
    await _repository.save(_settings!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Color _colorFor(String name) {
    switch (name) {
      case 'Blue':
        return AppColors.blue;
      case 'Purple':
        return AppColors.purple;
      case 'Red':
        return AppColors.red;
      case 'Green':
        return AppColors.green;
      case 'Orange':
        return AppColors.orange;
      default:
        return AppColors.blue;
    }
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
                    'APPEARANCE',
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
                        const Text('App Color',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _appColors.map((name) {
                            final isSelected = settings.appColor == name;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _settings = settings.copyWith(appColor: name);
                              }),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _colorFor(name),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _colorFor(name)
                                                .withValues(alpha: 0.6),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        const Text('Game Theme',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          children: _themes.map((name) {
                            final isSelected = settings.theme == name;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _settings =
                                      settings.copyWith(theme: name);
                                }),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? AppColors.accentGradient(
                                            AppColors.defaultAccent)
                                        : null,
                                    color:
                                        isSelected ? null : AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              if (settings != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.defaultAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
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