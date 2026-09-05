import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/room_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

/// Private Room host screen (T92).
///
/// Creates a room via POST /rooms/create, then polls GET /rooms/:code
/// every 3 seconds. When a guest joins, shows a START MATCH button
/// that calls POST /rooms/start and navigates to gameplay.
class PrivateRoomCreateScreen extends ConsumerStatefulWidget {
  final String? initialRoomCode;
  final String formatType;
  final String formatLabel;
  final VoidCallback onCancel;

  const PrivateRoomCreateScreen({
    super.key,
    this.initialRoomCode,
    required this.formatType,
    required this.formatLabel,
    required this.onCancel,
  });

  @override
  ConsumerState<PrivateRoomCreateScreen> createState() =>
      _PrivateRoomCreateScreenState();
}

class _PrivateRoomCreateScreenState
    extends ConsumerState<PrivateRoomCreateScreen> {
  String _roomCode = '';
  bool _isLoading = true;
  bool _isStarting = false;
  String? _error;
  bool _hasGuest = false;
  String? _guestName;
  Timer? _pollTimer;
  RoomService? _roomService;

  @override
  void initState() {
    super.initState();
    _createRoom();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (widget.initialRoomCode != null) {
      setState(() {
        _roomCode = widget.initialRoomCode!;
        _isLoading = false;
      });
      return;
    }

    try {
      final authClient = ref.read(authControllerProvider.notifier).client;
      final isAuth = await authClient.isAuthenticated;
      if (!isAuth) {
        if (!mounted) return;
        setState(() {
          _error = 'Please log in to create a room.';
          _isLoading = false;
        });
        return;
      }

      _roomService = RoomService(authClient);
      final result =
          await _roomService!.createRoom(formatType: widget.formatType);
      if (!mounted) return;

      setState(() {
        _roomCode = result['roomCode'] as String? ?? '';
        _isLoading = false;
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to create room. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollRoom());
  }

  Future<void> _pollRoom() async {
    if (_roomService == null || _roomCode.isEmpty) return;
    try {
      final status = await _roomService!.getRoomStatus(roomCode: _roomCode);
      if (!mounted) return;

      final hasGuest = status['hasGuest'] as bool? ?? false;
      final guestName = status['guestName'] as String?;
      final roomStatus = status['status'] as String?;

      if (roomStatus == 'active') {
        _pollTimer?.cancel();
        final matchId = status['matchId'];
        if (matchId != null) {
          context.go('/online-gameplay', extra: {'matchId': matchId});
        }
        return;
      }

      if (hasGuest && !_hasGuest) {
        setState(() {
          _hasGuest = true;
          _guestName = guestName;
        });
        _pollTimer?.cancel();
      }
    } catch (_) {
      // Polling errors are silent — keep trying.
    }
  }

  Future<void> _startMatch() async {
    if (_roomService == null) return;
    setState(() => _isStarting = true);

    try {
      final result = await _roomService!.startMatch(roomCode: _roomCode);
      if (!mounted) return;

      final matchId = result['matchId'];
      if (matchId != null) {
        context.go('/online-gameplay', extra: {'matchId': matchId});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isStarting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to start match. Please try again.')),
        );
      }
    }
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied to clipboard'),
        duration: Duration(seconds: 2),
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
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: widget.onCancel,
                    ),
                    const Expanded(
                      child: Text(
                        'ROOM CODE',
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

              // ── Room code card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1.5,
                    color: AppColors.defaultAccent.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.defaultAccent.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Share this code with your opponent',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.defaultAccent,
                        ),
                      )
                    else if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.red, fontSize: 14),
                      )
                    else
                      Text(
                        _roomCode,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!_isLoading && _error == null)
                      OutlinedButton.icon(
                        onPressed: () => _copyCode(context),
                        icon: const Icon(Icons.copy,
                            size: 16, color: Colors.white70),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          'COPY CODE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Match length display ────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    const Text('MATCH LENGTH',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 13)),
                    Text(widget.formatLabel,
                        style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Status / Start Match ────────────────────────────
              if (_hasGuest)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.green, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            '${_guestName ?? "Player"} joined!',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          onPressed: _isStarting ? null : _startMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.5),
                            ),
                          ),
                          child: _isStarting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'START MATCH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            AppColors.defaultAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'WAITING FOR PLAYER...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              // ── Cancel button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
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
}
