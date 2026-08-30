import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/match/widgets/theme_background.dart';
import '../../features/settings/settings_repository.dart';

class GameThemeController extends Notifier<GameTheme> {
  @override
  GameTheme build() {
    _loadInitial();
    return GameTheme.normal;
  }

  Future<void> _loadInitial() async {
    final settings = await SettingsRepository().load();
    state = settings.theme == 'Space' ? GameTheme.space : GameTheme.normal;
  }

  Future<void> setTheme(String name) async {
    state = name == 'Space' ? GameTheme.space : GameTheme.normal;
    final repo = SettingsRepository();
    final current = await repo.load();
    await repo.save(current.copyWith(theme: name));
  }

  /// Returns the correct hand image asset path for the active theme.
  String handAssetFor(String move) {
    final prefix = state == GameTheme.space ? 'space' : 'normal';
    return 'assets/images/$prefix/${prefix}_$move.png';
  }

  /// Returns the correct sound-folder prefix for the active theme
  /// (used by AudioService — wired fully once T74 adds theme-specific
  /// audio playback).
  String get audioFolder => state == GameTheme.space ? 'space' : 'normal';
}

final gameThemeProvider = NotifierProvider<GameThemeController, GameTheme>(
  GameThemeController.new,
);