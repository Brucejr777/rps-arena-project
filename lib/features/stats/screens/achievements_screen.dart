import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../local_stats_repository.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int progress;
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.progress = 0,
    this.target = 1,
  });
}

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  void _loadAchievements() async {
    final repo = LocalStatsRepository();
    final stats = await repo.load();
    final matchesPlayed = stats.matchesPlayed;
    final wins = stats.matchesWon;
    final roundsWon = stats.roundsWon;
    final streak = stats.currentStreak;

    _achievements = [
      Achievement(
        id: 'first_win',
        title: 'First Victory',
        description: 'Win your first match',
        icon: Icons.emoji_events,
        color: Colors.amber,
        isUnlocked: wins >= 1,
        progress: wins,
        target: 1,
      ),
      Achievement(
        id: 'win_streak_3',
        title: 'Hat Trick',
        description: 'Win 3 matches in a row',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isUnlocked: streak >= 3,
        progress: streak,
        target: 3,
      ),
      Achievement(
        id: 'win_streak_5',
        title: 'On Fire',
        description: 'Win 5 matches in a row',
        icon: Icons.whatshot,
        color: Colors.red,
        isUnlocked: streak >= 5,
        progress: streak,
        target: 5,
      ),
      Achievement(
        id: 'matches_10',
        title: 'Regular Player',
        description: 'Play 10 matches',
        icon: Icons.sports_martial_arts,
        color: Colors.blue,
        isUnlocked: matchesPlayed >= 10,
        progress: matchesPlayed,
        target: 10,
      ),
      Achievement(
        id: 'matches_50',
        title: 'Dedicated',
        description: 'Play 50 matches',
        icon: Icons.star,
        color: Colors.purple,
        isUnlocked: matchesPlayed >= 50,
        progress: matchesPlayed,
        target: 50,
      ),
      Achievement(
        id: 'wins_10',
        title: 'Rising Star',
        description: 'Win 10 matches',
        icon: Icons.trending_up,
        color: Colors.green,
        isUnlocked: wins >= 10,
        progress: wins,
        target: 10,
      ),
      Achievement(
        id: 'rounds_50',
        title: 'Round Master',
        description: 'Win 50 rounds',
        icon: Icons.timer,
        color: Colors.cyan,
        isUnlocked: roundsWon >= 50,
        progress: roundsWon,
        target: 50,
      ),
      Achievement(
        id: 'wins_25',
        title: 'Veteran',
        description: 'Win 25 matches',
        icon: Icons.military_tech,
        color: Colors.teal,
        isUnlocked: wins >= 25,
        progress: wins,
        target: 25,
      ),
      Achievement(
        id: 'wins_5',
        title: 'Getting Started',
        description: 'Win 5 matches',
        icon: Icons.star,
        color: Colors.lightGreen,
        isUnlocked: wins >= 5,
        progress: wins,
        target: 5,
      ),
      Achievement(
        id: 'matches_25',
        title: 'Regular',
        description: 'Play 25 matches',
        icon: Icons.sports,
        color: Colors.indigo,
        isUnlocked: matchesPlayed >= 25,
        progress: matchesPlayed,
        target: 25,
      ),
      Achievement(
        id: 'wins_100',
        title: 'Champion',
        description: 'Win 100 matches',
        icon: Icons.emoji_events,
        color: Colors.amber,
        isUnlocked: wins >= 100,
        progress: wins,
        target: 100,
      ),
      Achievement(
        id: 'matches_100',
        title: 'Dedicated Player',
        description: 'Play 100 matches',
        icon: Icons.workspace_premium,
        color: Colors.deepPurple,
        isUnlocked: matchesPlayed >= 100,
        progress: matchesPlayed,
        target: 100,
      ),
    ];
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(appAccentColorProvider);
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    // FIX: Navigate back to Profile instead of Single Player Setup
                    onPressed: () => context.go('/profile'),
                  ),
                  const Spacer(),
                  const Text(
                    'ACHIEVEMENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$unlockedCount / ${_achievements.length} Unlocked',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${(unlockedCount / _achievements.length * 100).round()}%',
                        style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: unlockedCount / _achievements.length,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Achievements list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  final achievement = _achievements[index];
                  return _buildAchievementCard(achievement);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final progress = achievement.isUnlocked
        ? 1.0
        : achievement.progress / achievement.target;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked ? achievement.color : AppColors.surface,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? achievement.color.withValues(alpha: 0.2)
                  : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: achievement.isUnlocked ? achievement.color : AppColors.surface,
              ),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked ? achievement.color : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        color: achievement.isUnlocked ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achievement.isUnlocked) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle, color: achievement.color, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.isUnlocked ? achievement.color : Colors.white24,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${achievement.progress} / ${achievement.target}',
                      style: TextStyle(
                        color: achievement.isUnlocked ? achievement.color : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}