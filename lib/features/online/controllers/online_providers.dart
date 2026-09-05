import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';

/// Online data providers (T121A).
///
/// Uses Dio-based AuthClient to fetch server data.
/// Each provider auto-refreshes when the screen opens.

/// Profile data (player info + stats)
class ProfileData {
  final Map<String, dynamic>? player;
  final Map<String, dynamic>? stats;

  const ProfileData({this.player, this.stats});

  factory ProfileData.empty() => const ProfileData();
}

final profileProvider = FutureProvider<ProfileData>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return ProfileData.empty();

  try {
    final client = ref.read(authControllerProvider.notifier).client;
    final response = await client.get('/auth/profile');
    final data = response.data as Map<String, dynamic>;
    return ProfileData(
      player: data['player'] as Map<String, dynamic>?,
      stats: data['stats'] as Map<String, dynamic>?,
    );
  } catch (_) {
    return ProfileData.empty();
  }
});

/// Online statistics only (no player info)
final onlineStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return {};

  try {
    final client = ref.read(authControllerProvider.notifier).client;
    final response = await client.get('/auth/statistics');
    return Map<String, dynamic>.from(response.data as Map);
  } catch (_) {
    return {};
  }
});

/// Match history
final matchHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return [];

  try {
    final client = ref.read(authControllerProvider.notifier).client;
    final response = await client.get('/matches/history');
    final data = response.data as Map<String, dynamic>;
    return (data['history'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    return [];
  }
});

/// Leaderboard
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final client = ref.read(authControllerProvider.notifier).client;
    final response = await client.get('/leaderboard');
    final data = response.data as Map<String, dynamic>;
    return (data['leaderboard'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    return [];
  }
});
