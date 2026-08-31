import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../match/domain/match_format.dart';

/// Quick Match setup screen (T86).
///
/// Controls: MATCH LENGTH selector, START SEARCH, BACK.
class QuickMatchSetupScreen extends StatefulWidget {
  const QuickMatchSetupScreen({super.key});

  @override
  State<QuickMatchSetupScreen> createState() => _QuickMatchSetupScreenState();
}

class _QuickMatchSetupScreenState extends State<QuickMatchSetupScreen> {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'QUICK MATCH',
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

              // ── Match Length ────────────────────────────────────
              const Text('Match Length',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openMatchLengthSelect,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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

              // ── Start Search ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO T87/T88: navigate to QuickMatchSearchingScreen
                    // passing the selected format to start the queue search
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'START SEARCH',
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
