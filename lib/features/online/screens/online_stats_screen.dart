import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

/// Online Statistics Screen (T120).
///
/// Displays the player's online match statistics.
/// Title: ONLINE STATISTICS
/// Fields: MATCHES PLAYED, MATCHES WON, MATCHES LOST, ROUNDS WON, ROUNDS LOST,
///         DRAWS, WIN RATE, ROCK USED, PAPER USED, SCISSORS USED
class OnlineStatsScreen extends ConsumerStatefulWidget {
  const OnlineStatsScreen({super.key});

  @override
  ConsumerState<OnlineStatsScreen> createState() => _OnlineStatsScreenState();
}

class _OnlineStatsScreenState extends ConsumerState<OnlineStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(authControllerProvider.notifier).client;
      final response = await client.get('/auth/profile');
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _stats = data['stats'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load statistics.';
        _isLoading = false;
      });
    }
  }

  Widget _statCard(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  const Expanded(
                    child: Text(
                      'ONLINE STATISTICS',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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
                      child: CircularProgressIndicator(color: AppColors.defaultAccent),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.white54)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchStats,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.defaultAccent),
                                child: const Text('RETRY', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchStats,
                          color: AppColors.defaultAccent,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // ── Match stats ─────────────────
                              const Text(
                                'MATCH RECORD',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      'MATCHES PLAYED',
                                      '${_stats?['matchesPlayed'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _statCard(
                                      'MATCHES WON',
                                      '${_stats?['matchesWon'] ?? 0}',
                                      valueColor: AppColors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _statCard(
                                      'MATCHES LOST',
                                      '${_stats?['matchesLost'] ?? 0}',
                                      valueColor: AppColors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Win Rate + Draws ─────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      'WIN RATE',
                                      '${_stats?['winRate'] ?? 0}%',
                                      valueColor: (_stats?['winRate'] ?? 0) >= 50
                                          ? AppColors.green
                                          : AppColors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _statCard(
                                      'DRAWS',
                                      '${_stats?['draws'] ?? 0}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ── Round stats ─────────────────
                              const Text(
                                'ROUND RECORD',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniStatCard(
                                      'ROUNDS WON',
                                      '${_stats?['roundsWon'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniStatCard(
                                      'ROUNDS LOST',
                                      '${_stats?['roundsLost'] ?? 0}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ── Move selection stats ─────────
                              const Text(
                                'MOVE SELECTIONS',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniStatCard(
                                      '🪨 ROCK',
                                      '${_stats?['rockSelections'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniStatCard(
                                      '📄 PAPER',
                                      '${_stats?['paperSelections'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniStatCard(
                                      '✂️ SCISSORS',
                                      '${_stats?['scissorsSelections'] ?? 0}',
                                    ),
                                  ),
                                ],
                              ),
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
