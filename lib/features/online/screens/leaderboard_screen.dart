import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';

/// Leaderboard Screen (T114).
///
/// Displays global leaderboard sorted by rating descending.
/// Title: GLOBAL LEADERBOARD
/// Columns: PLAYER | RATING
/// Refreshes when screen opens.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final AuthClient _client = AuthClient();
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.get('/leaderboard');
      final data = response.data as Map<String, dynamic>;
      final entries = (data['leaderboard'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _leaderboard = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard.';
        _isLoading = false;
      });
    }
  }

  Color _rankColor(String? tier) {
    switch (tier) {
      case 'Master':
        return AppColors.purple;
      case 'Diamond':
        return const Color(0xFF06B6D4);
      case 'Platinum':
        return const Color(0xFF8B5CF6);
      case 'Gold':
        return const Color(0xFFF59E0B);
      case 'Silver':
        return const Color(0xFF94A3B8);
      case 'Bronze':
        return const Color(0xFFCD7F32);
      default:
        return Colors.white54;
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
                      'GLOBAL LEADERBOARD',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // ── Column headers ───────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '#',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'PLAYER',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    'RATING',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Leaderboard list ─────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.defaultAccent,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchLeaderboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.defaultAccent,
                                ),
                                child: const Text('RETRY',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _leaderboard.isEmpty
                          ? const Center(
                              child: Text(
                                'No players yet.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchLeaderboard,
                              color: AppColors.defaultAccent,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _leaderboard.length,
                                itemBuilder: (context, index) {
                                  final entry = _leaderboard[index];
                                  final rank = entry['rank'] ?? index + 1;
                                  final username =
                                      entry['username'] ?? 'Unknown';
                                  final rating = entry['rating'] ?? 0;
                                  final tier = entry['rankTier'] as String?;
                                  final color = _rankColor(tier);

                                  // Top 3 highlighting
                                  final isTop3 = rank <= 3;
                                  final borderColor = isTop3
                                      ? color.withValues(alpha: 0.4)
                                      : Colors.white12;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isTop3
                                          ? color.withValues(alpha: 0.08)
                                          : AppColors.surface,
                                      border: Border.all(color: borderColor),
                                      borderRadius: index == 0
                                          ? const BorderRadius.vertical(
                                              top: Radius.circular(0))
                                          : index == _leaderboard.length - 1
                                              ? const BorderRadius.vertical(
                                                  bottom: Radius.circular(12))
                                              : null,
                                    ),
                                    child: Row(
                                      children: [
                                        // Position
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '$rank',
                                            style: TextStyle(
                                              color: isTop3
                                                  ? color
                                                  : Colors.white54,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Username + tier badge
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  color: isTop3
                                                      ? Colors.white
                                                      : Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: isTop3
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              if (tier != null)
                                                Text(
                                                  tier.toUpperCase(),
                                                  style: TextStyle(
                                                    color: color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Rating
                                        Text(
                                          '$rating',
                                          style: TextStyle(
                                            color: isTop3
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
