import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/settings_repository.dart';

class AnimationSpeedController extends Notifier<double> {
  @override
  double build() {
    _loadInitial();
    return 1.0; // FULL speed multiplier by default
  }

  Future<void> _loadInitial() async {
    final settings = await SettingsRepository().load();
    state = settings.animationSpeed == AnimationSpeed.fast ? 0.5 : 1.0;
  }

  void refreshFrom(AppSettings settings) {
    state = settings.animationSpeed == AnimationSpeed.fast ? 0.5 : 1.0;
  }
}

final animationSpeedProvider =
    NotifierProvider<AnimationSpeedController, double>(
  AnimationSpeedController.new,
);