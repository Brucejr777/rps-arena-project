import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Private Room guest screen (T94).
///
/// Step 1: Enter 6-character room code + JOIN button.
/// Step 2: After join, display room code, match length, host name.
class PrivateRoomJoinScreen extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function(String code) onJoin;
  final VoidCallback onCancel;

  const PrivateRoomJoinScreen({
    super.key,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  State<PrivateRoomJoinScreen> createState() => _PrivateRoomJoinScreenState();
}

class _PrivateRoomJoinScreenState extends State<PrivateRoomJoinScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // Set after a successful join
  Map<String, dynamic>? _roomInfo;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.length != 6) {
      setState(() {
        _error = 'Room code must be 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.onJoin(code);
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isLoading = false;
          _error = 'Room not found.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _roomInfo = result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to join room. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Post-join: show room info ──────────────────────────────
    if (_roomInfo != null) {
      return _buildRoomInfo();
    }

    // ── Pre-join: code input ──────────────────────────────────
    return _buildCodeInput();
  }

  Widget _buildCodeInput() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: widget.onCancel,
                    ),
                    const Expanded(
                      child: Text(
                        'JOIN ROOM',
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
              const SizedBox(height: 32),

              // ── Instructions ────────────────────────────────
              const Text(
                'Enter the room code shared by your opponent',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ── Code input ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _codeController,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: Colors.white38,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),

              // ── Error message ───────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const Spacer(),

              // ── Join button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'JOIN',
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

  Widget _buildRoomInfo() {
    final roomCode = _roomInfo!['roomCode'] as String? ?? '------';
    final formatType = _roomInfo!['formatType'] as String? ?? 'bestOf3';
    final hostName = _roomInfo!['hostName'] as String? ?? 'Host';

    String formatLabel;
    switch (formatType) {
      case 'bestOf3':
        formatLabel = 'BEST OF 3';
        break;
      case 'bestOf5':
        formatLabel = 'BEST OF 5';
        break;
      case 'bestOf7':
        formatLabel = 'BEST OF 7';
        break;
      case 'bestOf9':
        formatLabel = 'BEST OF 9';
        break;
      case 'unlimited':
        formatLabel = 'UNLIMITED';
        break;
      default:
        formatLabel = formatType.toUpperCase();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: widget.onCancel,
                    ),
                    const Expanded(
                      child: Text(
                        'JOIN ROOM',
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

              // ── Room info card ──────────────────────────────
              Container(
                width: double.infinity,
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
                    // Room code
                    const Text(
                      'ROOM CODE',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      roomCode,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    // Match length
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MATCH LENGTH',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                        Text(formatLabel,
                            style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Host name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('HOST',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                        Text(hostName,
                            style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Waiting message ─────────────────────────────
              const Text(
                'Waiting for host to start the match...',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
