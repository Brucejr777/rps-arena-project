import 'package:audioplayers/audioplayers.dart';
import '../../features/settings/settings_repository.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  double _masterVolume = 1.0;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.9;

  /// Call this once at app startup (and whenever settings change) to
  /// keep AudioService's volume levels in sync with saved preferences.
  Future<void> refreshVolumesFromSettings() async {
    final settings = await SettingsRepository().load();
    _masterVolume = settings.masterVolume;
    _musicVolume = settings.musicVolume;
    _sfxVolume = settings.soundEffectsVolume;
    await _musicPlayer.setVolume(_masterVolume * _musicVolume);
  }

  Future<void> playSound(String assetName) async {
    try {
      await _sfxPlayer.setVolume(_masterVolume * _sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/normal/normal_$assetName.mp3'));
    } catch (_) {
      // Asset not yet available — ignore silently.
    }
  }

  Future<void> playMusic(String themeFolder) async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_masterVolume * _musicVolume);
      await _musicPlayer.play(
        AssetSource('audio/$themeFolder/${themeFolder}_music.mp3'),
      );
    } catch (_) {
      // Asset not yet available — ignore silently.
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }
}