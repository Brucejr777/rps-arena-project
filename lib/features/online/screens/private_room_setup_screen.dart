import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../match/domain/match_format.dart';

/// Private Room setup screen — select match format before creating a room.
class PrivateRoomSetupScreen extends StatefulWidget {
  const PrivateRoomSetupScreen({super.key});

  @override
  State<PrivateRoomSetupScreen> createState() => _PrivateRoomSetupScreenState();
}

class _PrivateRoomSetupScreenState extends State<PrivateRoomSetupScreen> {
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

  String get _formatType {
    switch (selectedFormat.format) {
      case MatchFormat.bestOf3:
        return 'bestOf3';
      case MatchFormat.bestOf5:
        return 'bestOf5';
      case MatchFormat.bestOf7:
        return 'bestOf7';
      case MatchFormat.bestOf9:
        return 'bestOf9';
      case MatchFormat.custom:
        return 'custom';
      case MatchFormat.unlimited:
        return 'unlimited';
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
                        'PRIVATE ROOM',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatLabel,
                                style: const TextStyle(
                                    color: AppColors.primaryText, fontSize: 14)),
                            const Icon(Icons.chevron_right,
                                color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // ── Create Room button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.5),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF86EFAC),
                        Color(0xFF22C55E),
                      ],
                      stops: [0.2, 0.8],
                    ),
                    border: Border.all(
                      color: const Color(0xFF00E676),
                      width: 3,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        '/private-room-create',
                        extra: {
                          'formatType': _formatType,
                          'formatLabel': _formatLabel,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.5),
                      ),
                    ),
                    child: const Text(
                      'CREATE ROOM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Join Room button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/private-room-join');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.5),
                    ),
                  ),
                  child: const Text(
                    'JOIN ROOM',
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
