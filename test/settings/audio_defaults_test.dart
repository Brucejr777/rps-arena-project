import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rps_arena/features/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('volume defaults match spec: master 100%, music 70%, SFX 90%, vibration ON', () async {
    final repo = SettingsRepository();
    final settings = await repo.load();

    expect(settings.masterVolume, 1.0);
    expect(settings.musicVolume, 0.7);
    expect(settings.soundEffectsVolume, 0.9);
    expect(settings.vibrationEnabled, true);
  });

  test('volume settings persist after being changed', () async {
    final repo = SettingsRepository();
    await repo.save(const AppSettings(masterVolume: 0.5, musicVolume: 0.3));
    final reloaded = await repo.load();

    expect(reloaded.masterVolume, 0.5);
    expect(reloaded.musicVolume, 0.3);
  });
}