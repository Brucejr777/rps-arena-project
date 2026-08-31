import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// Plays a short sound effect by asset name (without extension).
  /// Safe no-op if the asset doesn't exist yet — assets are added in T70/T71.
  Future<void> playSound(String assetName) async {
    try {
      await _player.play(AssetSource('audio/normal/normal_$assetName.mp3'));
    } catch (_) {
      // Asset not yet available — ignore silently.
    }
  }
}