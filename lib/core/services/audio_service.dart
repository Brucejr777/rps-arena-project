import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../features/settings/settings_repository.dart';

/// Central audio service (T70 / T71 / T74).
///
/// Sound codes are linked to theme mp3 assets using the pattern:
///   assets/audio/<theme>/<theme>_<code>.mp3
///
/// Supported codes: click, transition, countdown, select, reveal,
/// victory, defeat, draw, opponent_found, connected, disconnected,
/// reconnect.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// Short sound-effects player (interrupts previous SFX automatically).
  final AudioPlayer _sfxPlayer = AudioPlayer();

  /// Looping background music player.
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

  /// Call whenever the active Game Theme changes so subsequent sounds
  /// and music use the correct theme's audio files.
  void setTheme(String themeFolder) {
    _themeFolder = themeFolder;
  }

  // ── Core linker: sound code -> theme mp3 asset ─────────────────
  Future<void> playSound(String code) async {
    final path = 'audio/$_themeFolder/${_themeFolder}_$code.mp3';
    try {
      await _sfxPlayer.setVolume(_masterVolume * _sfxVolume);
      await _sfxPlayer.play(AssetSource(path));
    } catch (e) {
      // Never swallow silently in debug builds so missing assets show up.
      debugPrint('AudioService: failed to play "$path": $e');
    }
  }

  // ── Named sound codes ──────────────────────────────────────────
  Future<void> playClick() => playSound('click');
  Future<void> playTransition() => playSound('transition');
  Future<void> playCountdown() => playSound('countdown');
  Future<void> playSelect() => playSound('select');
  Future<void> playReveal() => playSound('reveal');
  Future<void> playVictory() => playSound('victory');
  Future<void> playDefeat() => playSound('defeat');
  Future<void> playDraw() => playSound('draw');
  Future<void> playOpponentFound() => playSound('opponent_found');
  Future<void> playConnected() => playSound('connected');
  Future<void> playDisconnected() => playSound('disconnected');
  Future<void> playReconnect() => playSound('reconnect');

  // ── Background music ───────────────────────────────────────────
  Future<void> playMusic([String? themeFolder]) async {
    final folder = themeFolder ?? _themeFolder;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_masterVolume * _musicVolume);
      await _musicPlayer.play(AssetSource('audio/$folder/${folder}_music.mp3'));
    } catch (e) {
      debugPrint('AudioService: failed to play music: $e');
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }
}