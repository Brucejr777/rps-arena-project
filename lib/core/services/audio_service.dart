import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  Future<void> playSound(String assetName) async {
    try {
      await _sfxPlayer.play(AssetSource('audio/normal/normal_$assetName.mp3'));
    } catch (_) {
      // Asset not yet available — ignore silently.
    }
  }

  /// Starts looping background music for the given theme folder
  /// ('normal' or 'space'). Safe no-op if the asset isn't available yet.
  Future<void> playMusic(String themeFolder) async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
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

  Future<void> setMusicVolume(double volume) async {
    await _musicPlayer.setVolume(volume);
  }

  Future<void> setSfxVolume(double volume) async {
    await _sfxPlayer.setVolume(volume);
  }
}