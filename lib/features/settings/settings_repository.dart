import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/local_storage_keys.dart';

enum AnimationSpeed { full, fast }

class AppSettings {
  final String appColor; // 'Blue', 'Purple', 'Red', 'Green', 'Orange'
  final String theme; // 'Normal', 'Space'
  final double masterVolume; // 0.0 - 1.0
  final double musicVolume;
  final double soundEffectsVolume;
  final AnimationSpeed animationSpeed;
  final bool victoryAnimationsEnabled;
  final bool vibrationEnabled;

  const AppSettings({
    this.appColor = 'Blue',
    this.theme = 'Normal',
    this.masterVolume = 1.0,
    this.musicVolume = 0.7,
    this.soundEffectsVolume = 0.9,
    this.animationSpeed = AnimationSpeed.full,
    this.victoryAnimationsEnabled = true,
    this.vibrationEnabled = true,
  });

  AppSettings copyWith({
    String? appColor,
    String? theme,
    double? masterVolume,
    double? musicVolume,
    double? soundEffectsVolume,
    AnimationSpeed? animationSpeed,
    bool? victoryAnimationsEnabled,
    bool? vibrationEnabled,
  }) {
    return AppSettings(
      appColor: appColor ?? this.appColor,
      theme: theme ?? this.theme,
      masterVolume: masterVolume ?? this.masterVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      soundEffectsVolume: soundEffectsVolume ?? this.soundEffectsVolume,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      victoryAnimationsEnabled:
          victoryAnimationsEnabled ?? this.victoryAnimationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class SettingsRepository {
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      appColor: prefs.getString(LocalStorageKeys.selectedAppColor) ?? 'Blue',
      theme: prefs.getString(LocalStorageKeys.selectedTheme) ?? 'Normal',
      masterVolume: prefs.getDouble(LocalStorageKeys.masterVolume) ?? 1.0,
      musicVolume: prefs.getDouble(LocalStorageKeys.musicVolume) ?? 0.7,
      soundEffectsVolume:
          prefs.getDouble(LocalStorageKeys.soundEffectsVolume) ?? 0.9,
      animationSpeed:
          (prefs.getString(LocalStorageKeys.animationSpeed) ?? 'full') ==
                  'fast'
              ? AnimationSpeed.fast
              : AnimationSpeed.full,
      victoryAnimationsEnabled:
          prefs.getBool(LocalStorageKeys.victoryAnimationsEnabled) ?? true,
      vibrationEnabled:
          prefs.getBool(LocalStorageKeys.vibrationEnabled) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        LocalStorageKeys.selectedAppColor, settings.appColor);
    await prefs.setString(LocalStorageKeys.selectedTheme, settings.theme);
    await prefs.setDouble(
        LocalStorageKeys.masterVolume, settings.masterVolume);
    await prefs.setDouble(LocalStorageKeys.musicVolume, settings.musicVolume);
    await prefs.setDouble(
        LocalStorageKeys.soundEffectsVolume, settings.soundEffectsVolume);
    await prefs.setString(
      LocalStorageKeys.animationSpeed,
      settings.animationSpeed == AnimationSpeed.fast ? 'fast' : 'full',
    );
    await prefs.setBool(LocalStorageKeys.victoryAnimationsEnabled,
        settings.victoryAnimationsEnabled);
    await prefs.setBool(
        LocalStorageKeys.vibrationEnabled, settings.vibrationEnabled);
  }

  /// Restores all settings to their documented defaults:
  /// Blue, Normal, master 100%, music 70%, SFX 90%, FULL speed,
  /// victory animations ON, vibration ON.
  Future<void> resetToDefaults() async {
    await save(const AppSettings());
  }
}