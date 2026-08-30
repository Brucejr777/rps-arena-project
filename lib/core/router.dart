import 'package:go_router/go_router.dart';
import '../features/home/splash_screen.dart';
import '../features/home/main_menu_screen.dart';
import '../features/match/screens/single_player_setup_screen.dart';
import '../features/match/screens/match_format_select_screen.dart';
import '../features/match/screens/custom_match_config_screen.dart';
import '../features/match/widgets/standard_gameplay_screen.dart';
import '../features/match/widgets/unlimited_gameplay_screen.dart';

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
        isSignedIn: false, // TODO: replace with real auth state (T84 etc.)
        onSinglePlayer: () => context.push('/single-player-setup'),
        onTwoPlayers: () {
          // TODO T39: navigate to LocalSetupScreen once it exists
        },
        onMultiplayer: () {
          // TODO T85: navigate to MultiplayerScreen once it exists
        },
        onLeaderboard: () {
          // TODO T114: navigate to LeaderboardScreen once it exists
        },
        onSettings: () {
          // TODO T55/T66/T72: navigate to Settings once it exists
        },
        onProfile: () {
          // TODO T116: navigate to Player Profile once it exists
        },
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
  ],
);