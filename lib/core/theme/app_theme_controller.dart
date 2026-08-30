import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../../features/settings/settings_repository.dart';

class AppThemeController extends Notifier<Color> {
  @override
  Color build() {
    _loadInitial();
    return AppColors.defaultAccent; // Blue, matches default
  }

  Future<void> _loadInitial() async {
    final settings = await SettingsRepository().load();
    state = _colorFor(settings.appColor);
  }

  Future<void> setAppColor(String name) async {
    state = _colorFor(name);
    final repo = SettingsRepository();
    final current = await repo.load();
    await repo.save(current.copyWith(appColor: name));
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
}

final appAccentColorProvider = NotifierProvider<AppThemeController, Color>(
  AppThemeController.new,
);