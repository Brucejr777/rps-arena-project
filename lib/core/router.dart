import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/online/screens/multiplayer_screen.dart';
import '../features/online/screens/quick_match_setup_screen.dart';
import '../features/online/screens/quick_match_searching_screen.dart';
import '../features/online/screens/quick_match_create_screen.dart';
import '../features/online/screens/opponent_found_screen.dart';
import '../features/online/screens/private_room_create_screen.dart';
import '../features/online/screens/private_room_join_screen.dart';
import '../features/online/screens/private_room_setup_screen.dart';
import '../features/online/screens/online_match_loader_screen.dart';
import '../features/online/screens/connection_lost_screen.dart';
import '../features/online/screens/leaderboard_screen.dart';
import '../features/online/screens/player_profile_screen.dart';
import '../features/online/screens/match_history_screen.dart';
import '../features/online/screens/online_stats_screen.dart';
import '../features/home/splash_screen.dart';
import '../features/home/main_menu_screen.dart';
import '../features/match/screens/single_player_setup_screen.dart';
import '../features/match/screens/match_format_select_screen.dart';
import '../features/match/screens/custom_match_config_screen.dart';
import '../features/match/widgets/standard_gameplay_screen.dart';
import '../features/match/widgets/unlimited_gameplay_screen.dart';
import '../features/match/screens/local_setup_screen.dart';
import '../features/match/screens/local_match_flow_screen.dart';
import '../features/match/screens/time_attack_screen.dart';
import '../features/match/screens/tournament_screen.dart';
import '../features/match/domain/match_format.dart';
import '../features/match/screens/single_player_match_flow_screen.dart';
import '../features/match/domain/ai_service.dart';
import '../features/settings/screens/settings_home_screen.dart';
import '../features/settings/screens/appearance_screen.dart';
import '../features/settings/screens/data_screen.dart';
import '../features/stats/screens/view_statistics_screen.dart';
import '../features/stats/screens/achievements_screen.dart';
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
        onMultiplayer: () => context.push('/multiplayer'),
        onLeaderboard: () => context.push('/leaderboard'),
        onSettings: () => context.push('/settings'),
        onProfile: () => context.push('/profile'),
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
        final format =
            state.extra as MatchFormatConfig? ?? MatchFormatConfig.bestOf3();
        return LocalMatchFlowScreen(format: format);
      },
    ),
    GoRoute(
      path: '/time-attack',
      builder: (context, state) => const TimeAttackScreen(),
    ),
    GoRoute(
      path: '/tournament',
      builder: (context, state) => const TournamentScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/single-player-match',
      builder: (context, state) {
        final args = state.extra as (MatchFormatConfig, AiDifficulty);
        return SinglePlayerMatchFlowScreen(
          format: args.$1,
          difficulty: args.$2,
        );
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
      path: '/quick-match-setup',
      builder: (context, state) => const QuickMatchSetupScreen(),
    ),
    GoRoute(
      path: '/quick-match-create',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return QuickMatchCreateScreen(
          formatType: args['formatType'] as String? ?? 'bestOf3',
          formatLabel: args['formatLabel'] as String? ?? 'BEST OF 3',
          winsRequired: args['winsRequired'] as int? ?? 2,
          onCancel: () => context.go('/quick-match-setup'),
        );
      },
    ),
    GoRoute(
      path: '/quick-match-searching',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return QuickMatchSearchingScreen(
          formatType: args['formatType'] as String? ?? 'bestOf3',
          formatLabel: args['formatLabel'] as String? ?? 'BEST OF 3',
          winsRequired: args['winsRequired'] as int? ?? 2,
          rating: args['rating'] as int? ?? 1000,
          onCancel: () => context.go('/quick-match-setup'),
        );
      },
    ),
    GoRoute(
      path: '/opponent-found',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        final matchId = args['matchId'] as int?;

        return OpponentFoundScreen(
          matchId: matchId ?? 0,
          opponentName: args['opponentName'] as String? ?? 'Unknown',
          opponentRating: args['opponentRating'] as int? ?? 1000,
          onReady: () {
            if (matchId == null) return;
            context.push('/online-gameplay', extra: {
              'matchId': matchId,
              'playerName': null,
              'opponentName': args['opponentName'] as String?,
            });
          },
          onCancel: () => context.go('/quick-match-setup'),
        );
      },
    ),
    GoRoute(
      path: '/multiplayer',
      builder: (context, state) => MultiplayerScreen(
        onQuickMatch: () => context.push('/quick-match-setup'),
        onPrivateRoom: () => context.push('/private-room-setup'),
        onRankedMatch: () {
          // TODO T96: no ranked-match setup screen exists yet.
          // Backend route POST /ranked/join is ready (backend/routes/ranked.js).
        },
        onSettings: () => context.push('/settings'),
      ),
    ),
    GoRoute(
      path: '/private-room-setup',
      builder: (context, state) => const PrivateRoomSetupScreen(),
    ),
    GoRoute(
      path: '/private-room-create',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return PrivateRoomCreateScreen(
          initialRoomCode: args['roomCode'] as String?,
          formatType: args['formatType'] as String? ?? 'bestOf3',
          formatLabel: args['formatLabel'] as String? ?? 'BEST OF 3',
          onCancel: () => context.go('/main'),
        );
      },
    ),
    GoRoute(
      path: '/private-room-join',
      builder: (context, state) => PrivateRoomJoinScreen(
        onCancel: () => context.go('/main'),
      ),
    ),
    GoRoute(
      path: '/online-gameplay',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        final rawId = args['matchId'];
        final matchId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

        return OnlineMatchLoaderScreen(
          key: ValueKey(matchId),
          matchId: matchId,
          playerName: args['playerName'] as String?,
          opponentName: args['opponentName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const PlayerProfileScreen(),
    ),
    GoRoute(
      path: '/match-history',
      builder: (context, state) => const MatchHistoryScreen(),
    ),
    GoRoute(
      path: '/online-stats',
      builder: (context, state) => const OnlineStatsScreen(),
    ),
    GoRoute(
      path: '/connection-lost',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return ConnectionLostScreen(
          onReconnect: args['onReconnect'] as VoidCallback?,
          onExit: args['onExit'] as VoidCallback? ?? () => context.go('/main'),
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.uri}',
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
    ),
  ),
);