import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_client.dart';
import '../controllers/match_controller.dart';
import 'theme_background.dart';
import 'move_button.dart';
import 'pause_exit_overlay.dart';
import 'reveal_animation.dart';
import '../screens/standard_result_screen.dart';
import '../screens/unlimited_result_screen.dart';
import '../../online/screens/connection_lost_screen.dart';

/// Online gameplay screen (T99).
///
/// Connects to the server-authoritative match endpoint:
/// - Sends moves via POST /matches/{matchId}/move
/// - Waits for WebSocket round_result event
/// - Hides opponent selection until server reveals
class OnlineGameplayScreen extends ConsumerStatefulWidget {
  final int matchId;
  final int playerId;
  final String playerName;
  final int opponentId;
  final String opponentName;
  final String formatType;
  final int winsRequired;

  const OnlineGameplayScreen({
    super.key,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    required this.opponentId,
    required this.opponentName,
    required this.formatType,
    required this.winsRequired,
  });

  @override
  ConsumerState<OnlineGameplayScreen> createState() =>
      _OnlineGameplayScreenState();
}

class _OnlineGameplayScreenState extends ConsumerState<OnlineGameplayScreen> {
  late final AuthClient _authClient;
  late final MatchSocketClient _socketClient;
  StreamSubscription<SocketEvent>? _socketSub;

  int _playerScore = 0;
  int _opponentScore = 0;
  int _currentRound = 1;
  int _drawCount = 0;
  int _selectionTimer = 10;
  Timer? _timer;
  String? _selectedMove;
  bool _isWaitingForServer = false;
  bool _isRevealing = false;
  bool _isPaused = false;

  // Server-revealed data
  String? _serverPlayerAMove;
  String? _serverPlayerBMove;

  bool get _isPlayerA => widget.playerId == widget.opponentId
      ? true
      : widget.playerId < widget.opponentId;

  bool get _isUnlimited => widget.formatType == 'unlimited';
  bool get _canEndMatch => _isUnlimited && _drawCount + _playerScore + _opponentScore > 0;

  @override
  void initState() {
    super.initState();
    _authClient = AuthClient();
    _socketClient = MatchSocketClient();
    _connectWebSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).setMode(MatchMode.online);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketSub?.cancel();
    _socketClient.dispose();
    super.dispose();
  }

  void _connectWebSocket() {
    _socketClient.connect(widget.matchId);
    _socketSub = _socketClient.events.listen(_onSocketEvent);
  }

  void _onSocketEvent(SocketEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case SocketEventType.roundResult:
        _handleRoundResult(event.data);
        break;
      case SocketEventType.matchCompleted:
        _handleMatchCompleted(event.data);
        break;
      case SocketEventType.opponentDisconnected:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConnectionLostScreen()),
        );
        break;
      default:
        break;
    }
  }

  void _handleRoundResult(Map<String, dynamic> data) {
    final playerAMove = data['playerAMove'] as String?;
    final playerBMove = data['playerBMove'] as String?;
    final playerAScore = data['playerAScore'] as int? ?? 0;
    final playerBScore = data['playerBScore'] as int? ?? 0;
    final drawCount = data['drawCount'] as int? ?? 0;
    final totalRounds = data['totalRounds'] as int? ?? 0;
    final matchFinished = data['matchFinished'] as bool? ?? false;

    setState(() {
      _isWaitingForServer = false;
      _isRevealing = true;
      _serverPlayerAMove = playerAMove;
      _serverPlayerBMove = playerBMove;
      _playerScore = _isPlayerA ? playerAScore : playerBScore;
      _opponentScore = _isPlayerA ? playerBScore : playerAScore;
      _drawCount = drawCount;
    });

    // Show reveal for 2 seconds, then advance
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isRevealing = false;
        _serverPlayerAMove = null;
        _serverPlayerBMove = null;
      });

      if (matchFinished) {
        if (_isUnlimited) {
          final total = _playerScore + _opponentScore + _drawCount;
          final p1Rate = total == 0 ? 0.0 : (_playerScore / total) * 100;
          final p2Rate = total == 0 ? 0.0 : (_opponentScore / total) * 100;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => UnlimitedResultScreen(
                player1Wins: _playerScore,
                player2Wins: _opponentScore,
                draws: _drawCount,
                totalRounds: total,
                player1WinRate: p1Rate,
                player2WinRate: p2Rate,
                onPlayAgain: () => Navigator.of(context).maybePop(),
                onMainMenu: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          );
        } else {
          final playerWon = _playerScore > _opponentScore;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StandardResultScreen(
                playerWon: playerWon,
                playerScore: _playerScore,
                opponentScore: _opponentScore,
                onPlayAgain: () => Navigator.of(context).maybePop(),
                onMainMenu: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          );
        }
      } else {
        _currentRound = totalRounds + 1;
        _startRound();
      }
    });
  }

  void _handleMatchCompleted(Map<String, dynamic> data) {
    setState(() {
      _playerScore = _isPlayerA
          ? (data['playerAScore'] as int? ?? 0)
          : (data['playerBScore'] as int? ?? 0);
      _opponentScore = _isPlayerA
          ? (data['playerBScore'] as int? ?? 0)
          : (data['playerAScore'] as int? ?? 0);
      _drawCount = data['drawCount'] as int? ?? 0;
    });
    final total = _playerScore + _opponentScore + _drawCount;
    final p1Rate = total == 0 ? 0.0 : (_playerScore / total) * 100;
    final p2Rate = total == 0 ? 0.0 : (_opponentScore / total) * 100;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UnlimitedResultScreen(
          player1Wins: _playerScore,
          player2Wins: _opponentScore,
          draws: _drawCount,
          totalRounds: total,
          player1WinRate: p1Rate,
          player2WinRate: p2Rate,
          onPlayAgain: () => Navigator.of(context).maybePop(),
          onMainMenu: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  void _startRound() {
    setState(() {
      _selectedMove = null;
      _selectionTimer = 10;
      _isWaitingForServer = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_selectionTimer <= 1) {
        timer.cancel();
        // Auto-select if player hasn't chosen
        if (_selectedMove == null) {
          final moves = ['rock', 'paper', 'scissors'];
          _selectMove(moves[DateTime.now().millisecond % 3]);
        }
        _submitMove();
      } else {
        setState(() => _selectionTimer--);
      }
    });
  }

  void _selectMove(String move) {
    if (_selectedMove != null || _isWaitingForServer) return;
    setState(() => _selectedMove = move);
    _submitMove();
  }

  Future<void> _submitMove() async {
    if (_selectedMove == null || _isWaitingForServer) return;

    setState(() => _isWaitingForServer = true);
    _timer?.cancel();

    try {
      await _authClient.post(
        '/matches/${widget.matchId}/move',
        data: {'move': _selectedMove},
      );
      // Result will arrive via WebSocket
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWaitingForServer = false;
        _selectedMove = null;
      });
    }
  }

  void _onExitPressed() {
    ref.read(matchControllerProvider.notifier).pause();
    setState(() => _isPaused = true);
  }

  void _onResume() {
    ref.read(matchControllerProvider.notifier).resume();
    setState(() => _isPaused = false);
  }

  void _onExitConfirmed() {
    final outcome = ref.read(matchControllerProvider.notifier).attemptExit();
    setState(() => _isPaused = false);

    switch (outcome) {
      case ExitOutcome.connectionLost:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConnectionLostScreen()),
        );
        break;
      case ExitOutcome.rankedQuitLoss:
        Navigator.of(context).maybePop();
        break;
      case ExitOutcome.exitedCleanly:
      case ExitOutcome.resumed:
        Navigator.of(context).maybePop();
        break;
    }
  }

  // ── Unlimited END MATCH (T103) ──────────────────────────────
  void _onEndMatchPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('END MATCH?',
            style: TextStyle(color: AppColors.primaryText)),
        content: Text(
          'Current Score: $_playerScore - $_opponentScore',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitEndMatch();
            },
            child: const Text('END MATCH', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEndMatch() async {
    try {
      setState(() => _isWaitingForServer = true);
      _timer?.cancel();
      await _authClient.post('/matches/${widget.matchId}/end');
      // Result arrives via WebSocket match_completed event
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWaitingForServer = false);
    }
  }

  Widget _handImage(String? move, {required bool isPlayer}) {
    final themeController = ref.read(gameThemeProvider.notifier);
    final asset = move == null
        ? themeController.handAssetFor('rock')
        : themeController.handAssetFor(move);
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.read(gameThemeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ThemeBackground(
        theme: ref.watch(gameThemeProvider),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: _onExitPressed,
                        ),
                        Text(
                          'ROUND $_currentRound',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        // END MATCH button (Unlimited only, after first round)
                        if (_canEndMatch && !_isWaitingForServer)
                          TextButton(
                            onPressed: _onEndMatchPressed,
                            child: const Text(
                              'END MATCH',
                              style: TextStyle(
                                color: AppColors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Score ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _playerScoreCard(widget.playerName, _playerScore),
                        Column(
                          children: [
                            Text(
                              '$_selectionTimer',
                              style: TextStyle(
                                color: _selectionTimer <= 5
                                    ? AppColors.red
                                    : AppColors.primaryText,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isWaitingForServer)
                              const Text(
                                'WAITING...',
                                style: TextStyle(
                                  color: AppColors.defaultAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        _playerScoreCard(widget.opponentName, _opponentScore),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Hands ───────────────────────────────────
                    const Spacer(),
                    if (_isRevealing &&
                        _serverPlayerAMove != null &&
                        _serverPlayerBMove != null)
                      RevealAnimation(
                        playerAMove: _serverPlayerAMove!,
                        playerBMove: _serverPlayerBMove!,
                        handAssetFor: themeController.handAssetFor,
                        playerALabel: widget.playerName,
                        playerBLabel: widget.opponentName,
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _handImage(_selectedMove, isPlayer: true),
                          Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          _handImage(null, isPlayer: false),
                        ],
                      ),
                    const Spacer(),

                    // ── Move buttons ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MoveButton(
                          move: 'rock',
                          icon: Icons.circle,
                          isSelected: _selectedMove == 'rock',
                          isDisabled: _selectedMove != null || _isWaitingForServer,
                          onSelected: () => _selectMove('rock'),
                        ),
                        MoveButton(
                          move: 'paper',
                          icon: Icons.square,
                          isSelected: _selectedMove == 'paper',
                          isDisabled: _selectedMove != null || _isWaitingForServer,
                          onSelected: () => _selectMove('paper'),
                        ),
                        MoveButton(
                          move: 'scissors',
                          icon: Icons.content_cut,
                          isSelected: _selectedMove == 'scissors',
                          isDisabled: _selectedMove != null || _isWaitingForServer,
                          onSelected: () => _selectMove('scissors'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (_isPaused)
                PauseExitOverlay(
                  onResume: _onResume,
                  onExit: _onExitConfirmed,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerScoreCard(String name, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(name,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
