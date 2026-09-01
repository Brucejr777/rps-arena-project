import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/rank_badge.dart';

/// Player Profile Screen (T116).
///
/// Displays:
/// - Username
/// - Rank (with badge)
/// - Rating
/// - Matches, Wins, Losses
/// - Win Rate
/// - MATCH HISTORY button
/// - ONLINE STATISTICS button
///
/// No profile picture.
class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  Map<String, dynamic>? _player;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the same AuthClient that handled login — shares token storage.
      final client = ref.read(authControllerProvider.notifier).client;
      final response = await client.get('/auth/profile');
      final data = response.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _player = data['player'] as Map<String, dynamic>?;
        _stats = data['stats'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String errorMsg;
      if (msg.contains('401') || msg.contains('expired') || msg.contains('Invalid')) {
        errorMsg = 'Session expired. Please go back and log in again.';
      } else if (msg.contains('Connection') || msg.contains('timeout')) {
        errorMsg = 'Connection failed. Please try again.';
      } else {
        errorMsg = 'Failed to load profile.';
      }
      setState(() {
        _error = errorMsg;
        _isLoading = false;
      });
    }
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed,
      {bool primary = false}) {
    return SizedBox(
      width: double.infinity,
      child: primary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.defaultAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  const Expanded(
                    child: Text(
                      'PLAYER PROFILE',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.defaultAccent),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchProfile,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.defaultAccent),
                                  child: const Text('RETRY',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchProfile,
                          color: AppColors.defaultAccent,
                          child: ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              // ── Avatar placeholder ────────────
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: RankBadge.colorFor(
                                          _player?['rank'] ?? 'Bronze'),
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (_player?['username'] ?? 'P')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── Username ──────────────────────
                              Center(
                                child: Text(
                                  _player?['username'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ── Rank badge + Rating ───────────
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RankBadge(
                                        rank: _player?['rank'] ?? 'Bronze'),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_player?['rating'] ?? 1000} ELO',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Stats grid ───────────────────
                              Row(
                                children: [
                                  _statBox('MATCHES',
                                      '${_stats?['matchesPlayed'] ?? 0}'),
                                  const SizedBox(width: 8),
                                  _statBox(
                                      'WINS', '${_stats?['matchesWon'] ?? 0}'),
                                  const SizedBox(width: 8),
                                  _statBox('LOSSES',
                                      '${_stats?['matchesLost'] ?? 0}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _statBox('WIN RATE',
                                      '${_stats?['winRate'] ?? 0}%'),
                                  const SizedBox(width: 8),
                                  _statBox(
                                      'DRAWS', '${_stats?['draws'] ?? 0}'),
                                  const SizedBox(
                                      width: 8),
                                  _statBox(
                                      'ROUNDS',
                                      '${(_stats?['roundsWon'] ?? 0) + (_stats?['roundsLost'] ?? 0)}'),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Action buttons ───────────────
                              _actionButton('MATCH HISTORY', () {
                                context.push('/match-history');
                              }),
                              const SizedBox(height: 12),
                              _actionButton('ONLINE STATISTICS', () {
                                context.push('/online-stats');
                              }),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
