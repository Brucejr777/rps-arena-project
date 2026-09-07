import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Opponent found screen (T89/T90).
///
/// Shows after a Quick Match pairing. Displays opponent info, a READY button,
/// and a 15-second countdown. If either player fails to confirm, the match
/// is cancelled.
///
/// Corrected behavior:
/// - Countdown is 15 seconds, matching T89/T90.
/// - The first player who presses READY and receives "waiting" is now able
///   to detect when the second player also confirms via polling.
/// - Polling handles:
///   - ready_up  -> stay on this screen
///   - confirmed -> both players ready, proceed to match
///   - idle      -> match cancelled
/// - READY failures no longer permanently cancel the countdown.
class OpponentFoundScreen extends StatefulWidget {
  final int matchId;
  final String opponentName;
  final int opponentRating;
  final VoidCallback onReady;
  final VoidCallback onCancel;

  const OpponentFoundScreen({
    super.key,
    required this.matchId,
    required this.opponentName,
    required this.opponentRating,
    required this.onReady,
    required this.onCancel,
  });

  @override
  State<OpponentFoundScreen> createState() => _OpponentFoundScreenState();
}

class _OpponentFoundScreenState extends State<OpponentFoundScreen> {
  static const int _countdownDuration = 15;

  int _secondsRemaining = _countdownDuration;

  bool _isReady = false;
  bool _isSubmitting = false;
  bool _isPolling = false;
  bool _hasNavigated = false;
  bool _isCancelled = false;

  String? _errorMessage;

  Timer? _timer;
  Timer? _pollTimer;

  late final AuthClient _authClient;

  @override
  void initState() {
    super.initState();
    _authClient = AuthClient();

    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _hasNavigated || _isCancelled) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        _handleCancelled(
          'Match cancelled — ready period expired.',
        );
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _hasNavigated || _isCancelled || _isPolling) {
        return;
      }

      _isPolling = true;

      try {
        final res = await _authClient.get('/quick-match/status');

        if (!mounted || _hasNavigated || _isCancelled) {
          return;
        }

        final data = res.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'confirmed') {
          _proceedToMatch();
        } else if (status == 'idle') {
          _handleCancelled(
            'Match cancelled — opponent did not confirm.',
          );
        }
      } catch (_) {
        // Polling failed — retry on next tick.
      } finally {
        _isPolling = false;
      }
    });
  }

  void _proceedToMatch() {
    if (_hasNavigated || _isCancelled) return;

    _hasNavigated = true;
    _timer?.cancel();
    _pollTimer?.cancel();

    if (mounted) {
      widget.onReady();
    }
  }

  void _handleCancelled(String message) {
    if (_hasNavigated || _isCancelled) return;

    _isCancelled = true;
    _timer?.cancel();
    _pollTimer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      widget.onCancel();
    }
  }

  Future<void> _onClosePressed() async {
    if (_hasNavigated || _isCancelled) return;

    _isCancelled = true;
    _timer?.cancel();
    _pollTimer?.cancel();

    try {
      await _authClient.delete('/quick-match/cancel');
    } catch (_) {
      // Best-effort cancel.
    }

    if (mounted) {
      widget.onCancel();
    }
  }

  Future<void> _onReadyPressed() async {
    if (_isSubmitting || _isReady || _hasNavigated || _isCancelled) {
      return;
    }

    if (widget.matchId <= 0) {
      setState(() {
        _errorMessage = 'Invalid match.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await _authClient.post(
        '/quick-match/ready',
        data: {'matchId': widget.matchId},
      );

      if (!mounted || _hasNavigated || _isCancelled) return;

      final data = res.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'confirmed' || status == 'already_confirmed') {
        _proceedToMatch();
        return;
      }

      // Status is "waiting": this player is ready, but the opponent
      // has not confirmed yet. Keep the countdown running and poll.
      setState(() {
        _isReady = true;
        _isSubmitting = false;
      });
    } on DioException catch (e) {
      if (!mounted || _isCancelled) return;

      final msg = (e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)['error'] as String?
          : null;

      setState(() {
        _isSubmitting = false;
        _errorMessage = msg ?? 'Ready-up failed. Please try again.';
      });
    } catch (_) {
      if (!mounted || _isCancelled) return;

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Ready-up failed. Please try again.';
      });
    }
  }

  String get _countdownText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _countdownColor {
    if (_secondsRemaining <= 5) return AppColors.red;
    if (_secondsRemaining <= 10) return AppColors.orange;
    return AppColors.primaryText;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _onClosePressed,
                    ),
                    const Expanded(
                      child: Text(
                        'OPPONENT FOUND',
                        style: TextStyle(
                          color: AppColors.green,
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

              // ── Opponent info card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1.5,
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your opponent',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.opponentName,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rating: ${widget.opponentRating}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Countdown ───────────────────────────────────────
              Text(
                _countdownText,
                style: TextStyle(
                  color: _countdownColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Time remaining to confirm',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),

              const Spacer(),

              // ── Error message ───────────────────────────────────
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // ── Ready / Waiting status ──────────────────────────
              if (_isReady)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'WAITING FOR OPPONENT...',
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onReadyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'READY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              fontSize: 16,
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