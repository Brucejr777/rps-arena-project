import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Online multiplayer hub screen (T85).
///
/// Controls: QUICK MATCH, PRIVATE ROOM, RANKED MATCH, BACK.
class MultiplayerScreen extends StatelessWidget {
  final VoidCallback onQuickMatch;
  final VoidCallback onPrivateRoom;
  final VoidCallback onRankedMatch;

  const MultiplayerScreen({
    super.key,
    required this.onQuickMatch,
    required this.onPrivateRoom,
    required this.onRankedMatch,
  });

  Widget _menuButton(String label, VoidCallback onPressed,
      {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: primary
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.defaultAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
              // ── Header ──────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'MULTIPLAYER',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // ── Menu buttons ────────────────────────────────────
              _menuButton('QUICK MATCH', onQuickMatch, primary: true),
              _menuButton('PRIVATE ROOM', onPrivateRoom),
              _menuButton('RANKED MATCH', onRankedMatch),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
