import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rps_arena/features/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default settings match documented defaults', () async {
    final repo = SettingsRepository();
    final settings = await repo.load();

    expect(settings.appColor, 'Blue');
    expect(settings.theme, 'Normal');
    expect(settings.masterVolume, 1.0);
    expect(settings.musicVolume, 0.7);
    expect(settings.soundEffectsVolume, 0.9);
    expect(settings.animationSpeed, AnimationSpeed.full);
    expect(settings.victoryAnimationsEnabled, true);
    expect(settings.vibrationEnabled, true);
  });

  test('resetToDefaults restores defaults after changes', () async {
    final repo = SettingsRepository();
    await repo.save(const AppSettings(
      appColor: 'Red',
      theme: 'Space',
      masterVolume: 0.3,
      animationSpeed: AnimationSpeed.fast,
      victoryAnimationsEnabled: false,
      vibrationEnabled: false,
    ));

    var settings = await repo.load();
    expect(settings.appColor, 'Red');

    await repo.resetToDefaults();
    settings = await repo.load();

    expect(settings.appColor, 'Blue');
    expect(settings.theme, 'Normal');
    expect(settings.masterVolume, 1.0);
    expect(settings.animationSpeed, AnimationSpeed.full);
    expect(settings.victoryAnimationsEnabled, true);
    expect(settings.vibrationEnabled, true);
  });
}