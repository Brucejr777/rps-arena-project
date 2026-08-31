import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rps_arena/core/theme/animation_speed_controller.dart';
import 'package:rps_arena/features/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('FULL speed gives multiplier 1.0, FAST gives 0.5', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(animationSpeedProvider.notifier);

    controller.refreshFrom(const AppSettings(animationSpeed: AnimationSpeed.full));
    expect(container.read(animationSpeedProvider), 1.0);

    controller.refreshFrom(const AppSettings(animationSpeed: AnimationSpeed.fast));
    expect(container.read(animationSpeedProvider), 0.5);
  });
}