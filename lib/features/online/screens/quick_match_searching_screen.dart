import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Quick Match searching screen (T88).
///
/// Joins the Quick Match queue on init and polls for a match.
/// When matched, navigates to the opponent-found screen.
class QuickMatchSearchingScreen extends StatefulWidget {
  final String formatType;
  final String formatLabel;
  final int winsRequired;
  final int rating;
  final VoidCallback onCancel;

  const QuickMatchSearchingScreen({
    super.key,
    required this.formatType,
    required this.formatLabel,
    required this.winsRequired,
    required this.rating,
    required this.onCancel,
  });

  @override
  State<QuickMatchSearchingScreen> createState() =>
      _QuickMatchSearchingScreenState();
}

class _QuickMatchSearchingScreenState extends State<QuickMatchSearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late final AuthClient _authClient;
  Timer? _pollTimer;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _authClient = AuthClient();
    _joinQueue();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _joinQueue() async {
    setState(() { _joining = true; _error = null; });
    try {
      final res = await _authClient.post(
        '/quick-match/join',
        data: {
          'formatType': widget.formatType,
          'winsRequired': widget.winsRequired,
        },
      );
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'matched') {
        _navigateToOpponentFound(data);
        return;
      }

      // Enqueued — start polling for match
      setState(() => _joining = false);
      _startPolling();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)['error'] as String?
          : null;
      setState(() { _error = msg ?? 'Failed to join queue.'; _joining = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to join queue.'; _joining = false; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final res = await _authClient.get('/quick-match/status');
        if (!mounted) return;
        final data = res.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'idle') {
          _pollTimer?.cancel();
          return;
        }
      } catch (_) {
        // Polling failed — will retry on next tick
      }
    });
  }

  void _navigateToOpponentFound(Map<String, dynamic> data) {
    _pollTimer?.cancel();
    final matchId = data['matchId'] as int?;
    final opponent = data['opponent'] as Map<String, dynamic>?;
    if (matchId == null || opponent == null) return;

    context.push('/opponent-found', extra: {
      'matchId': matchId,
      'opponentName': opponent['username'] as String? ?? 'Unknown',
      'opponentRating': opponent['rating'] as int? ?? 1000,
    });
  }

  Future<void> _cancelQueue() async {
    _pollTimer?.cancel();
    try {
      await _authClient.delete('/quick-match/cancel');
    } catch (_) {
      // Best-effort cancel
    }
    if (mounted) widget.onCancel();
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
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _cancelQueue,
                    ),
                    const Expanded(
                      child: Text(
                        'QUICK MATCH',
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
              const Spacer(),

              // ── Searching indicator ─────────────────────────────
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.defaultAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Status text ──────────────────────────────────
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                )
              else if (_joining)
                const Text(
                  'JOINING QUEUE...',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                )
              else
                const Text(
                  'SEARCHING FOR OPPONENT...',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              const SizedBox(height: 32),

              // ── Info cards ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _infoRow('Rating', '${widget.rating}'),
                    const SizedBox(height: 12),
                    _infoRow('MATCH LENGTH', widget.formatLabel),
                  ],
                ),
              ),

              const Spacer(),

              // ── Cancel button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelQueue,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
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

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
