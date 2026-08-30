import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/match_format.dart';
import '../domain/ai_service.dart';
import 'match_format_select_screen.dart';

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
  final result = await Navigator.of(context).push<MatchFormatConfig>(
    MaterialPageRoute(builder: (_) => const MatchFormatSelectScreen()),
  );
  if (result != null) {
    if (result.format == MatchFormat.custom) {
      // TODO T25: navigate to CustomMatchConfigScreen instead, then
      // setState with the real winsRequired the player enters.
    } else {
      setState(() => selectedFormat = result);
    }
  }
}

  Widget _difficultyOption(String label, AiDifficulty value) {
    final isSelected = selectedDifficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedDifficulty = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColors.accentGradient(AppColors.defaultAccent)
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'SINGLE PLAYER',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Difficulty',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _difficultyOption('EASY', AiDifficulty.easy),
                  _difficultyOption('NORMAL', AiDifficulty.normal),
                  _difficultyOption('HARD', AiDifficulty.hard),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Match Length',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openMatchLengthSelect,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatLabel,
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 14)),
                      const Icon(Icons.chevron_right, color: Colors.white38),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: navigate to StandardGameplayScreen or
                    // UnlimitedGameplayScreen based on selectedFormat,
                    // passing selectedDifficulty into the AI service.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'START MATCH',
                    style: TextStyle(
                      color: Colors.white,
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