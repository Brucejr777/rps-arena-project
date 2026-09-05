import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../local_stats_repository.dart';

class ViewStatisticsScreen extends StatefulWidget {
  const ViewStatisticsScreen({super.key});

  @override
  State<ViewStatisticsScreen> createState() => _ViewStatisticsScreenState();
}

class _ViewStatisticsScreenState extends State<ViewStatisticsScreen> {
  final LocalStatsRepository _repository = LocalStatsRepository();
  LocalStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _repository.load();
    setState(() => _stats = stats);
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'STATISTICS',
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
              const SizedBox(height: 24),
              if (stats == null)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.defaultAccent,
                    ),
                  ),
                )
              else
                Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _statRow('MATCHES PLAYED', '${stats.matchesPlayed}'),
                          _statRow('MATCHES WON', '${stats.matchesWon}'),
                          _statRow('MATCHES LOST', '${stats.matchesLost}'),
                          const Divider(color: Colors.white24, height: 24),
                          _statRow('ROUNDS WON', '${stats.roundsWon}'),
                          _statRow('ROUNDS LOST', '${stats.roundsLost}'),
                          _statRow('DRAWS', '${stats.draws}'),
                          const Divider(color: Colors.white24, height: 24),
                          _statRow('WIN RATE',
                              '${stats.winRate.toStringAsFixed(1)}%'),
                          const Divider(color: Colors.white24, height: 24),
                          _statRow('ROCK USED', '${stats.rockSelections}'),
                          _statRow('PAPER USED', '${stats.paperSelections}'),
                          _statRow(
                              'SCISSORS USED', '${stats.scissorsSelections}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}