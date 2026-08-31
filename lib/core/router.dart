import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/splash_screen.dart';
import '../features/home/main_menu_screen.dart';
import '../features/match/screens/single_player_setup_screen.dart';
import '../features/match/screens/match_format_select_screen.dart';
import '../features/match/screens/custom_match_config_screen.dart';
import '../features/match/widgets/standard_gameplay_screen.dart';
import '../features/match/widgets/unlimited_gameplay_screen.dart';
import '../features/match/screens/local_setup_screen.dart';
import '../features/match/screens/local_match_flow_screen.dart';
import '../features/match/domain/match_format.dart';
import '../features/match/screens/single_player_match_flow_screen.dart';
import '../features/match/domain/ai_service.dart';
import '../features/settings/screens/settings_home_screen.dart';
import '../features/settings/screens/appearance_screen.dart';
import '../features/settings/screens/data_screen.dart';
import '../features/stats/screens/view_statistics_screen.dart';
import 'package:flutter/material.dart';
import '../features/settings/screens/gameplay_settings_screen.dart';
import '../features/settings/screens/audio_settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => SplashScreen(
        onFinished: () => context.go('/main'),
      ),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => MainMenuScreen(
        onSinglePlayer: () => context.push('/single-player-setup'),
        onTwoPlayers: () => context.push('/local-setup'),
        onMultiplayer: () {
          // TODO T85: navigate to MultiplayerScreen once it exists
        },
        onLeaderboard: () {
          // TODO T114: navigate to LeaderboardScreen once it exists
        },
        onSettings: () => context.push('/settings'),
        onProfile: () {
          // TODO T116: navigate to Player Profile once it exists
        },
        onLogin: () => context.push('/login'),
        onRegister: () => context.push('/register'),
      ),
    ),
    GoRoute(
      path: '/single-player-setup',
      builder: (context, state) => const SinglePlayerSetupScreen(),
    ),
    GoRoute(
      path: '/match-format-select',
      builder: (context, state) => const MatchFormatSelectScreen(),
    ),
    GoRoute(
      path: '/custom-match-config',
      builder: (context, state) => const CustomMatchConfigScreen(),
    ),
    GoRoute(
      path: '/standard-gameplay',
      builder: (context, state) => const StandardGameplayScreen(),
    ),
    GoRoute(
      path: '/unlimited-gameplay',
      builder: (context, state) => const UnlimitedGameplayScreen(),
    ),
    GoRoute(
      path: '/local-setup',
      builder: (context, state) => const LocalSetupScreen(),
    ),
    GoRoute(
      path: '/local-match',
      builder: (context, state) {
        final format = state.extra as MatchFormatConfig? ?? MatchFormatConfig.bestOf3();
        return LocalMatchFlowScreen(format: format);
      },
    ),
    GoRoute(
      path: '/single-player-match',
      builder: (context, state) {
        final args = state.extra as (MatchFormatConfig, AiDifficulty);
        return SinglePlayerMatchFlowScreen(format: args.$1, difficulty: args.$2);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsHomeScreen(
        onAppearance: () => context.push('/settings/appearance'),
        onAudio: () => context.push('/settings/audio'),
        onGameplay: () => context.push('/settings/gameplay'),
        onData: () => context.push('/settings/data'),
      ),
    ),
    GoRoute(
      path: '/settings/appearance',
      builder: (context, state) => const AppearanceScreen(),
    ),
    GoRoute(
      path: '/settings/data',
      builder: (context, state) => DataScreen(
        onViewStatistics: () => context.push('/settings/data/statistics'),
        onResetLocalStatistics: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Local statistics reset')),
          );
        },
        onResetSettings: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings reset to defaults')),
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/data/statistics',
      builder: (context, state) => const ViewStatisticsScreen(),
    ),
    GoRoute(
      path: '/settings/gameplay',
      builder: (context, state) => const GameplaySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/audio',
      builder: (context, state) => const AudioSettingsScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);