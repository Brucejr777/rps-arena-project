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
  String _themeFolder = 'normal'; // 'normal' or 'space'

  Future<void> refreshVolumesFromSettings() async {
    final settings = await SettingsRepository().load();
    _masterVolume = settings.masterVolume;
    _musicVolume = settings.musicVolume;
    _sfxVolume = settings.soundEffectsVolume;
    _themeFolder = settings.theme == 'Space' ? 'space' : 'normal';
    await _musicPlayer.setVolume(_masterVolume * _musicVolume);
  }

  /// Call this whenever the active Game Theme changes so subsequent
  /// sound effects and music use the correct theme's audio files.
  void setTheme(String themeFolder) {
    _themeFolder = themeFolder;
  }

  Future<void> playSound(String assetName) async {
    try {
      await _sfxPlayer.setVolume(_masterVolume * _sfxVolume);
      await _sfxPlayer.play(
        AssetSource('audio/$_themeFolder/${_themeFolder}_$assetName.mp3'),
      );
    } catch (_) {
      // Asset not yet available — ignore silently.
    }
  }

  Future<void> playMusic([String? themeFolder]) async {
    final folder = themeFolder ?? _themeFolder;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_masterVolume * _musicVolume);
      await _musicPlayer.play(
        AssetSource('audio/$folder/${folder}_music.mp3'),
      );
    } catch (_) {
      // Asset not yet available — ignore silently.
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }
}