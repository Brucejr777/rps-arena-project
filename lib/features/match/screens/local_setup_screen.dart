import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hero_title.dart';
import '../../../core/widgets/mode_card.dart';
import '../../../core/widgets/input_card.dart';
import '../domain/match_format.dart';

class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
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
                        '2 PLAYERS',
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
                    'LOCAL',
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

              // ── Mode cards (2-Player only) ─────────────────────
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
                          context.push('/local-match', extra: selectedFormat);
                        },
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_calendar.svg',
                        title: 'CUSTOM MATCH',
                        subtitle: 'Flexible rules',
                        subtitle2: 'Choose format & rules',
                        badgeLabel: 'LOCAL',
                        badgeColor: AppColors.svgCyan,
                        iconColor: AppColors.svgCyan,
                        onTap: _openMatchLengthSelect,
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
                    context.push('/local-match', extra: selectedFormat);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── BACK button (T39 requirement) ──────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.5),
                    ),
                  ),
                  child: const Text(
                    'BACK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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