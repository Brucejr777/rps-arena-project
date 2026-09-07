import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Quick Match create screen.
///
/// Joins the Quick Match queue on init and polls for a match.
/// When matched, navigates to the opponent-found screen.
class QuickMatchCreateScreen extends StatefulWidget {
  final String formatType;
  final String formatLabel;
  final int winsRequired;
  final VoidCallback onCancel;

  const QuickMatchCreateScreen({
    super.key,
    required this.formatType,
    required this.formatLabel,
    required this.winsRequired,
    required this.onCancel,
  });

  @override
  State<QuickMatchCreateScreen> createState() => _QuickMatchCreateScreenState();
}

class _QuickMatchCreateScreenState extends State<QuickMatchCreateScreen> {
  late final AuthClient _authClient;
  Timer? _pollTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _authClient = AuthClient();
    _joinQueue();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _joinQueue() async {
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

      // If searching, start polling.
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join queue: $e')),
      );
      widget.onCancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;

      try {
        final res = await _authClient.get('/quick-match/status');
        if (!mounted) return;

        final data = res.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'ready_up' || status == 'confirmed') {
          _pollTimer?.cancel();
          _navigateToOpponentFoundFromStatus(data);
          return;
        }

        if (status == 'idle') {
          _pollTimer?.cancel();

          if (mounted && !_isCancelling) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Match search ended.'),
              ),
            );

            widget.onCancel();
          }
        }
      } catch (_) {
        // Polling failed — retry on next tick.
      }
    });
  }

  void _navigateToOpponentFound(Map<String, dynamic> data) {
    _pollTimer?.cancel();

    final matchId = data['matchId'] as int?;
    final opponent = data['opponent'] as Map<String, dynamic>?;

    if (matchId == null || opponent == null) return;

    if (!mounted) return;

    context.push('/opponent-found', extra: {
      'matchId': matchId,
      'opponentName': opponent['username'] as String? ?? 'Unknown',
      'opponentRating': opponent['rating'] as int? ?? 1000,
    });
  }

  void _navigateToOpponentFoundFromStatus(Map<String, dynamic> data) {
    final matchId = data['matchId'] as int?;
    if (matchId == null) return;

    final opponent = data['opponent'] as Map<String, dynamic>?;

    final opponentName = opponent?['username'] as String? ??
        data['opponentName'] as String? ??
        'Unknown';

    final opponentRating = opponent?['rating'] as int? ?? 1000;

    if (!mounted) return;

    context.push('/opponent-found', extra: {
      'matchId': matchId,
      'opponentName': opponentName,
      'opponentRating': opponentRating,
    });
  }

  Future<void> _cancelSearch() async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
    });

    _pollTimer?.cancel();

    try {
      await _authClient.delete('/quick-match/cancel');
    } catch (_) {
      // Ignore cancel errors.
    }

    if (!mounted) return;
    
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'QUICK MATCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.formatLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'WAITING FOR OPPONENT...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _cancelSearch,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isCancelling ? 'CANCELLING...' : 'CANCEL',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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