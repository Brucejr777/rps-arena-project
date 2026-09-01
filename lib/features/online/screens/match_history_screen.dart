import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../widgets/rank_badge.dart';

/// Match History Screen (T119).
///
/// Displays the player's online match history.
/// Title: MATCH HISTORY
/// Fields: date, opponent, mode, format, result, rating_before, rating_after, rank_change
class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final AuthClient _client = AuthClient();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.get('/matches/history');
      final data = response.data as Map<String, dynamic>;
      final entries = (data['history'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _history = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load match history.';
        _isLoading = false;
      });
    }
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return AppColors.green;
      case 'loss':
        return AppColors.red;
      case 'draw':
        return AppColors.orange;
      default:
        return Colors.white54;
    }
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'quick_match':
        return 'QUICK';
      case 'private_room':
        return 'PRIVATE';
      case 'ranked':
        return 'RANKED';
      default:
        return mode.toUpperCase();
    }
  }

  String _formatLabel(String format) {
    switch (format) {
      case 'bestOf3':
        return 'Bo3';
      case 'bestOf5':
        return 'Bo5';
      case 'bestOf7':
        return 'Bo7';
      case 'bestOf9':
        return 'Bo9';
      case 'unlimited':
        return '∞';
      default:
        return format;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
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
                      'MATCH HISTORY',
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
                                onPressed: _fetchHistory,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.defaultAccent),
                                child: const Text('RETRY', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _history.isEmpty
                          ? const Center(
                              child: Text(
                                'No match history yet.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchHistory,
                              color: AppColors.defaultAccent,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final entry = _history[index];
                                  final result = entry['result'] ?? 'draw';
                                  final opponent = entry['opponent_name'] ?? 'Unknown';
                                  final mode = entry['mode'] ?? '';
                                  final format = entry['format_type'] ?? '';
                                  final ratingBefore = entry['rating_before'] ?? 0;
                                  final ratingAfter = entry['rating_after'] ?? 0;
                                  final rankChange = entry['rank_change'] as String?;
                                  final dateStr = entry['created_at'] as String?;
                                  final color = _resultColor(result);

                                  final ratingDiff = ratingAfter - ratingBefore;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ── Top row: Result + Opponent + Date
                                        Row(
                                          children: [
                                            // Result badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                result.toUpperCase(),
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Opponent
                                            Expanded(
                                              child: Text(
                                                'vs $opponent',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Date
                                            Text(
                                              _formatDate(dateStr),
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // ── Bottom row: Mode, Format, Rating change
                                        Row(
                                          children: [
                                            // Mode badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _modeLabel(mode),
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Format
                                            Text(
                                              _formatLabel(format),
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const Spacer(),
                                            // Rating change
                                            Text(
                                              '$ratingBefore → $ratingAfter',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (ratingDiff != 0) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                ratingDiff > 0 ? '+$ratingDiff' : '$ratingDiff',
                                                style: TextStyle(
                                                  color: ratingDiff > 0
                                                      ? AppColors.green
                                                      : AppColors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        // ── Rank change row ──
                                        if (rankChange != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.trending_up,
                                                  size: 12, color: Colors.white38),
                                              const SizedBox(width: 4),
                                              RankBadge(
                                                rank: rankChange.split(' → ').last.trim(),
                                                fontSize: 9,
                                                showIcon: false,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rankChange,
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
