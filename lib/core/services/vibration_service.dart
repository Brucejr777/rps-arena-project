import 'package:vibration/vibration.dart';
import '../../features/settings/settings_repository.dart';

class VibrationService {
  VibrationService._();
  static final VibrationService instance = VibrationService._();

  bool _vibrationEnabled = true;

  Future<void> refreshFromSettings() async {
    final settings = await SettingsRepository().load();
    _vibrationEnabled = settings.vibrationEnabled;
  }

  Future<void> _vibrate(int durationMs) async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: durationMs);
      }
    } catch (_) {
      // Device doesn't support vibration or plugin unavailable — ignore.
    }
  }

  Future<void> selection() => _vibrate(80);
  Future<void> reveal() => _vibrate(80);
  Future<void> victory() => _vibrate(150);
  Future<void> defeat() => _vibrate(150);
  Future<void> draw() => _vibrate(60);
}