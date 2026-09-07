import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hero_title.dart';
import '../../../core/widgets/mode_card.dart';
import '../../../core/widgets/input_card.dart';
import '../domain/match_format.dart';
import '../domain/ai_service.dart';
import 'package:go_router/go_router.dart';

class SinglePlayerSetupScreen extends StatefulWidget {
  const SinglePlayerSetupScreen({super.key});

  @override
  State<SinglePlayerSetupScreen> createState() =>
      _SinglePlayerSetupScreenState();
}

class _SinglePlayerSetupScreenState extends State<SinglePlayerSetupScreen> {
  AiDifficulty selectedDifficulty = AiDifficulty.easy;
  MatchFormatConfig selectedFormat = MatchFormatConfig.bestOf3();

  String get _formatLabel {
    switch (selectedFormat.format) {
      case MatchFormat.bestOf3:
        return 'BEST OF 3';
      case MatchFormat.bestOf5:
        return 'BEST OF 5';
      case MatchFormat.bestOf7:
        return 'BEST OF 7';
      case MatchFormat.bestOf9:
        return 'BEST OF 9';
      case MatchFormat.custom:
        return 'CUSTOM (${selectedFormat.winsRequired})';
      case MatchFormat.unlimited:
        return 'UNLIMITED';
    }
  }

  Future<void> _openMatchLengthSelect() async {
    final result = await context.push<MatchFormatConfig>('/match-format-select');
    if (!mounted) return;
    if (result == null) return;

    if (result.format == MatchFormat.custom) {
      final customResult =
          await context.push<MatchFormatConfig>('/custom-match-config');
      if (!mounted) return;
      if (customResult != null) {
        setState(() => selectedFormat = customResult);
      }
    } else {
      setState(() => selectedFormat = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
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
                        'SINGLE PLAYER',
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
              const SizedBox(height: 4),

              // ── Hero title ─────────────────────────────────────
              const Center(
                child: HeroTitle(first: 'RPS', second: 'ARENA', fontSize: 26),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ──────────────────────────────────────
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF03BBE8), Color(0xFFC631E0)],
                    stops: [0.2, 0.8],
                  ).createShader(bounds),
                  child: const Text(
                    'SINGLE PLAYER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Mode cards ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ModeCard(
                        iconAsset: 'assets/icons/icon_bolt.svg',
                        title: 'QUICK MATCH',
                        subtitle: _formatLabel,
                        subtitle2: 'Fastest pairing',
                        badgeLabel: 'LOCAL',
                        badgeColor: AppColors.badgeGreen,
                        iconColor: AppColors.svgGreen,
                        onTap: () {
                          context.push(
                            '/single-player-match',
                            extra: (selectedFormat, selectedDifficulty),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_calendar.svg',
                        title: 'CUSTOM MATCH',
                        subtitle: 'Flexible rules',
                        subtitle2: 'Invite friends',
                        badgeLabel: 'ONLINE',
                        badgeColor: AppColors.svgCyan,
                        iconColor: AppColors.svgCyan,
                        onTap: _openMatchLengthSelect,
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_settings.svg',
                        title: 'DIFFICULTY',
                        subtitle: 'Easy / Normal / Hard / Expert / Asian',
                        subtitle2: 'Choose your challenge',
                        badgeLabel: 'NEW',
                        badgeColor: AppColors.svgOrange,
                        iconColor: AppColors.svgOrange,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _buildDifficultyPicker(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_timer.svg',
                        title: 'TIME ATTACK',
                        subtitle: '30 seconds per move',
                        subtitle2: 'Race the clock against CPU',
                        badgeLabel: 'AI',
                        badgeColor: AppColors.svgOrange,
                        iconColor: AppColors.svgOrange,
                        onTap: () {
                          context.push('/time-attack');
                        },
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_trophy.svg',
                        title: 'TOURNAMENT',
                        subtitle: 'Elimination rounds',
                        subtitle2: '8 players vs AI',
                        badgeLabel: 'AI',
                        badgeColor: AppColors.svgDarkRed,
                        iconColor: AppColors.svgDarkRed,
                        onTap: () {
                          context.push('/tournament');
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Start button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: GradientPillButton(
                  label: 'START MATCH',
                  isLoading: false,
                  onPressed: () {
                    context.push(
                      '/single-player-match',
                      extra: (selectedFormat, selectedDifficulty),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyPicker() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'DIFFICULTY',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          _buildDifficultyOption(
            'EASY',
            AiDifficulty.easy,
            AppColors.green,
            Icons.star_border,
          ),
          const SizedBox(height: 8),
          _buildDifficultyOption(
            'NORMAL',
            AiDifficulty.normal,
            AppColors.orange,
            Icons.star_half,
          ),
          const SizedBox(height: 8),
          _buildDifficultyOption(
            'HARD',
            AiDifficulty.hard,
            AppColors.red,
            Icons.star,
          ),
          const SizedBox(height: 8),
          _buildDifficultyOption(
            'EXPERT',
            AiDifficulty.expert,
            AppColors.purple,
            Icons.stars,
          ),
          const SizedBox(height: 8),
          _buildDifficultyOption(
            'ASIAN',
            AiDifficulty.asian,
            AppColors.magenta,
            Icons.whatshot,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(
    String label,
    AiDifficulty value,
    Color color,
    IconData icon,
  ) {
    final isSelected = selectedDifficulty == value;

    return GestureDetector(
      onTap: () {
        setState(() => selectedDifficulty = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}