import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../match/widgets/online_gameplay_screen.dart';

/// Resolves match participants before entering online gameplay.
///
/// Takes a [matchId] plus optional display names, fetches
/// GET /matches/:matchId/state to determine the player A/B ids and
/// format, maps the signed-in user to the correct side, then builds
/// [OnlineGameplayScreen].
class OnlineMatchLoaderScreen extends ConsumerStatefulWidget {
  final int matchId;
  final String? playerName;
  final String? opponentName;

  const OnlineMatchLoaderScreen({
    super.key,
    required this.matchId,
    this.playerName,
    this.opponentName,
  });

  @override
  ConsumerState<OnlineMatchLoaderScreen> createState() =>
      _OnlineMatchLoaderScreenState();
}

class _OnlineMatchLoaderScreenState
    extends ConsumerState<OnlineMatchLoaderScreen> {
  Map<String, dynamic>? _resolved;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final auth = ref.read(authControllerProvider.notifier).client;
      final authState = ref.read(authControllerProvider);
      final res = await auth.get('/matches/${widget.matchId}/state');
      if (!mounted) return;

      final data = res.data as Map<String, dynamic>;
      final playerAId = (data['playerAId'] as num).toInt();
      final playerBId = (data['playerBId'] as num).toInt();
      final myId = authState.playerId;
      final iAmA = myId == null || myId == playerAId;

      setState(() {
        _resolved = {
          'isPlayerA': iAmA,
          'playerId': iAmA ? playerAId : playerBId,
          'opponentId': iAmA ? playerBId : playerAId,
          'playerName': widget.playerName ??
              authState.username ??
              (iAmA ? 'Player A' : 'Player B'),
          'opponentName': widget.opponentName ?? 'Opponent',
          'formatType': data['formatType'] as String? ?? 'bestOf3',
          'winsRequired': (data['winsRequired'] as num?)?.toInt() ?? 2,
        };
      });
    } catch (e) {
      debugPrint('Online match resolve failed: $e');
      if (!mounted) return;
      setState(() => _error = 'Failed to load match. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.go('/main'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'BACK TO MENU',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_resolved == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.defaultAccent,
            ),
          ),
        ),
      );
    }

    final r = _resolved!;
    return OnlineGameplayScreen(
      matchId: widget.matchId,
      playerId: r['playerId'] as int,
      playerName: r['playerName'] as String,
      opponentId: r['opponentId'] as int,
      opponentName: r['opponentName'] as String,
      formatType: r['formatType'] as String,
      winsRequired: r['winsRequired'] as int,
      isPlayerA: r['isPlayerA'] as bool,
    );
  }
}
