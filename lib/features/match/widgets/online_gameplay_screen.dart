import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_client.dart';
import '../../auth/controllers/auth_controller.dart';
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
  /// Whether the local player is player A in the match record.
  /// Passed explicitly — player ids carry no ordering guarantee.
  final bool isPlayerA;

  const OnlineGameplayScreen({
    super.key,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    required this.opponentId,
    required this.opponentName,
    required this.formatType,
    required this.winsRequired,
    required this.isPlayerA,
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
  bool _isAutoMove = false;
  bool _isWaitingForServer = false;
  bool _isRevealing = false;
  bool _isPaused = false;
  bool _opponentConnected = false;

  // Safety net: if the server doesn't respond within 3 seconds,
  // poll the match state endpoint and either resolve the round or
  // let the player retry.
  Timer? _waitingTimeout;

  // Server-revealed data
  String? _serverPlayerAMove;
  String? _serverPlayerBMove;
  bool _serverPlayerAAuto = false;
  bool _serverPlayerBAuto = false;

  // Guards against handling the same round_result twice (once from the
  // POST response, once from the WebSocket broadcast).
  bool _roundResolved = false;

  // Set after a round's reveal ends — the client waits for the server's
  // round_start event before beginning the next round.  This prevents
  // Player 2 (who gets the HTTP response first) from racing ahead.
  bool _waitingForNextRound = false;

  // ── Pick lock (role-agnostic) ─────────────────────────────
  // Set synchronously on tap to prevent double-submit for BOTH players.
  bool _hasPicked = false;

  // ── Rematch state ──────────────────────────────────────────
  bool _showResult = false;
  bool _showRematchRequest = false;
  bool _isRematchWaiting = false;
  int? _rematchRequesterId;
  String? _rematchRequesterName;
  Timer? _rematchCountdown;
  Timer? _rematchPollTimer;

  bool get _isPlayerA => widget.isPlayerA;
  bool get _isUnlimited => widget.formatType == 'unlimited';
  bool get _canEndMatch => _isUnlimited && _drawCount + _playerScore + _opponentScore > 0;

  @override
  void initState() {
    super.initState();
    _authClient = ref.read(authControllerProvider.notifier).client;
    _socketClient = MatchSocketClient();
    _connectWebSocket();

    // Safety: if round_start doesn't arrive within 5s (opponent may have
    // disconnected before we connected), start the round anyway.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_opponentConnected) {
        _opponentConnected = true;
        _startRound();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).setMode(MatchMode.online);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitingTimeout?.cancel();
    _rematchCountdown?.cancel();
    _rematchPollTimer?.cancel();
    _socketSub?.cancel();
    _socketClient.dispose();
    super.dispose();
  }

  void _connectWebSocket() {
    _socketClient.connect(widget.matchId, playerId: widget.playerId);
    _socketSub?.cancel();
    _socketSub = _socketClient.events.listen(
      _onSocketEvent,
      onError: (_) {
        // Socket errors trigger the client's own reconnect loop.
      },
    );
  }

  /// Coerce server numbers defensively (pg COUNT columns arrive as strings).
  int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  void _onSocketEvent(SocketEvent event) {
    if (!mounted) return;

    // The server broadcasts to every connected client — ignore events
    // belonging to other matches.
    final eventMatchId = event.data['matchId'];
    if (eventMatchId != null && '$eventMatchId' != '${widget.matchId}') return;

    print('[OnlineGameplay] WS event: type=${event.type}, matchId=$eventMatchId, '
        'data=${event.data}');

    switch (event.type) {
      case SocketEventType.roundStart:
        if (!_opponentConnected) {
          _opponentConnected = true;
          _startRound();
        } else if (_waitingForNextRound) {
          _waitingForNextRound = false;
          _waitingTimeout?.cancel();
          _startRound();
        }
        break;
      case SocketEventType.roundResult:
        _handleRoundResult(event.data);
        break;
      case SocketEventType.matchCompleted:
        _handleMatchCompleted(event.data);
        break;
      case SocketEventType.opponentDisconnected:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConnectionLostScreen(
              onReconnect: () {
                Navigator.of(context).pop();
                _connectWebSocket();
              },
              onExit: () {
                if (mounted) GoRouter.of(context).go('/main');
              },
            ),
          ),
        );
        break;
      case SocketEventType.rematchRequested:
        setState(() {
          _showRematchRequest = true;
          _rematchRequesterId = event.data['requesterId'] as int?;
          _rematchRequesterName = event.data['requesterName'] as String?;
        });
        _startRematchCountdown();
        break;
      case SocketEventType.rematchAccepted:
        _handleRematchAccepted(event.data);
        break;
      case SocketEventType.rematchDeclined:
        _rematchPollTimer?.cancel();
        setState(() {
          _isRematchWaiting = false;
          _showRematchRequest = false;
        });
        break;
      case SocketEventType.matchCancelled:
        _rematchCountdown?.cancel();
        _rematchPollTimer?.cancel();
        setState(() {
          _isRematchWaiting = false;
          _showRematchRequest = false;
          _showResult = false;
        });
        if (mounted) {
          final reason = event.data['reason'] as String? ?? 'unknown';
          final msg = reason == 'opponent_not_ready'
              ? 'Opponent did not confirm the match.'
              : 'Match cancelled.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          GoRouter.of(context).go('/quick-match-setup');
        }
        break;
      default:
        break;
    }
  }

  void _handleRoundResult(Map<String, dynamic> data) {
    if (_roundResolved) {
      print('[OnlineGameplay] _handleRoundResult: IGNORED (round already resolved)');
      return;
    }

    // Guard against stale events from a previous round.  After _startRound()
    // resets _roundResolved, a late WS broadcast or poll for the old round
    // must not overwrite the new round's state.
    final eventRound = _asInt(data['roundNumber']);
    if (eventRound < _currentRound) {
      print('[OnlineGameplay] _handleRoundResult: IGNORED stale round '
          '$eventRound (current=$_currentRound)');
      return;
    }

    _roundResolved = true;
    _waitingTimeout?.cancel();

    final playerAMove = data['playerAMove'] as String?;
    final playerBMove = data['playerBMove'] as String?;
    final playerAScore = _asInt(data['playerAScore']);
    final playerBScore = _asInt(data['playerBScore']);
    final drawCount = _asInt(data['drawCount']);
    final totalRounds = _asInt(data['totalRounds']);
    final matchFinished = data['matchFinished'] as bool? ?? false;

    print('[OnlineGameplay] _handleRoundResult: isPlayerA=$_isPlayerA, '
        'serverScores=${playerAScore}-${playerBScore}, '
        'myScore=${_isPlayerA ? playerAScore : playerBScore}, '
        'oppScore=${_isPlayerA ? playerBScore : playerAScore}, '
        'round=$totalRounds, finished=$matchFinished, '
        'movesA=$playerAMove, movesB=$playerBMove');

    setState(() {
      _isWaitingForServer = false;
      _isRevealing = true;
      _serverPlayerAMove = playerAMove;
      _serverPlayerBMove = playerBMove;
      _serverPlayerAAuto = data['playerAAuto'] as bool? ?? false;
      _serverPlayerBAuto = data['playerBAuto'] as bool? ?? false;
      _playerScore = _isPlayerA ? playerAScore : playerBScore;
      _opponentScore = _isPlayerA ? playerBScore : playerAScore;
      _drawCount = drawCount;
    });

    // Show reveal for 1 second, then advance
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isRevealing = false;
        _serverPlayerAMove = null;
        _serverPlayerBMove = null;
        _serverPlayerAAuto = false;
        _serverPlayerBAuto = false;
      });

      if (matchFinished) {
        _timer?.cancel();
        setState(() {
          _showResult = true;
          _showRematchRequest = false;
          _isRematchWaiting = false;
        });
      } else {
        _currentRound = totalRounds + 1;

        // Wait for the server's round_start event so both players begin
        // the next round together.  Safety timeout: if round_start doesn't
        // arrive within 3s (e.g. WS hiccup), start anyway.
        _waitingForNextRound = true;
        _waitingTimeout?.cancel();
        _waitingTimeout = Timer(const Duration(seconds: 3), () {
          if (mounted && _waitingForNextRound) {
            _waitingForNextRound = false;
            _startRound();
          }
        });
      }
    });
  }

  void _handleMatchCompleted(Map<String, dynamic> data) {
    setState(() {
      _playerScore = _isPlayerA
          ? _asInt(data['playerAScore'])
          : _asInt(data['playerBScore']);
      _opponentScore = _isPlayerA
          ? _asInt(data['playerBScore'])
          : _asInt(data['playerAScore']);
      _drawCount = _asInt(data['drawCount']);
      _showResult = true;
      _showRematchRequest = false;
      _isRematchWaiting = false;
    });
  }

  void _startRound() {
    _waitingTimeout?.cancel();
    _pollRetries = 0;

    setState(() {
      _selectedMove = null;
      _isAutoMove = false;
      _selectionTimer = 10;
      _isWaitingForServer = false;
      _roundResolved = false;
      _waitingForNextRound = false;
      _hasPicked = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_selectionTimer <= 1) {
        timer.cancel();
        if (_selectedMove == null) {
          final moves = ['rock', 'paper', 'scissors'];
          setState(() {
            _selectedMove = moves[DateTime.now().millisecond % 3];
            _isAutoMove = true;
          });
        }
        _submitMove();
      } else {
        setState(() => _selectionTimer--);
      }
    });
  }

  void _selectMove(String move) {
    if (_hasPicked || _selectedMove != null || _isWaitingForServer) return;
    setState(() {
      _hasPicked = true;
      _selectedMove = move;
      _isAutoMove = false;
    });
    _submitMove();
  }

  Future<void> _submitMove() async {
    if (_selectedMove == null || _isWaitingForServer) return;

    print('[OnlineGameplay] _submitMove: move=$_selectedMove, round=$_currentRound');
    setState(() => _isWaitingForServer = true);
    _timer?.cancel();

    // Start safety-net timer: if the server doesn't deliver a round_result
    // within 3 seconds, poll the state endpoint to catch up.
    _waitingTimeout?.cancel();
    _pollRetries = 0;
    _waitingTimeout = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isWaitingForServer) return;
      _pollRoundState();
    });

    try {
      final res = await _authClient.post(
        '/matches/${widget.matchId}/move',
        data: {'move': _selectedMove},
      );

      // The second submitter gets the resolved round inline in the HTTP
      // response — handle it directly so a missed socket event can't
      // leave the screen stuck on WAITING (the duplicate broadcast is
      // ignored via _roundResolved).
      final data = res.data;
      print('[OnlineGameplay] _submitMove HTTP response: $data');
      if (data is Map<String, dynamic> && data['type'] == 'round_result') {
        _waitingTimeout?.cancel();
        if (!mounted) return;
        _handleRoundResult(data);
        return;
      }

      // Otherwise the result will arrive via WebSocket.
      // Poll after 500ms as a faster fallback (stale-round guard prevents
      // double-handling if WS delivers first).
      _waitingTimeout?.cancel();
      _waitingTimeout = Timer(const Duration(milliseconds: 500), () {
        if (!mounted || !_isWaitingForServer) return;
        _pollRoundState();
      });
    } catch (e) {
      _waitingTimeout?.cancel();
      if (!mounted) return;
      setState(() {
        _isWaitingForServer = false;
        _selectedMove = null;
        _hasPicked = false;
      });
    }
  }

  /// Called when the WAITING timeout fires — poll the server to see if the
  /// current round has been resolved (maybe the WS event was missed).
  /// Retries up to [maxRetries] times if the round is still pending.
  int _pollRetries = 0;
  static const int _maxPollRetries = 5;

  Future<void> _pollRoundState() async {
    _pollRetries++;
    print('[OnlineGameplay] _pollRoundState: retry=$_pollRetries/$_maxPollRetries, round=$_currentRound');
    try {
      final res = await _authClient.get('/matches/${widget.matchId}/state');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        _resetWaiting();
        return;
      }

      final rounds = data['rounds'] as List<dynamic>? ?? [];
      final matchFinished = data['winnerId'] != null ||
          (data['matchDraw'] as bool? ?? false);

      // Find the round matching the one we're waiting on.
      for (final r in rounds) {
        if (r is Map<String, dynamic> && r['roundNumber'] == _currentRound) {
          final result = r['result'] as String?;
          if (result != null && result != 'pending') {
            // Round was resolved server-side but the WS event was missed.
            final synthetic = <String, dynamic>{
              'type': 'round_result',
              'matchId': widget.matchId,
              'roundNumber': _currentRound,
              'playerAMove': r['playerAMove'],
              'playerBMove': r['playerBMove'],
              'result': result,
              'playerAScore': data['playerAScore'] ?? 0,
              'playerBScore': data['playerBScore'] ?? 0,
              'drawCount': data['drawCount'] ?? 0,
              'totalRounds': data['totalRounds'] ?? _currentRound,
              'matchFinished': matchFinished,
              'winnerId': data['winnerId'],
            };
            _waitingTimeout?.cancel();
            _pollRetries = 0;
            if (mounted) _handleRoundResult(synthetic);
            return;
          }
        }
      }

      // Round still pending — retry if we haven't exhausted retries.
      if (_pollRetries < _maxPollRetries) {
        _waitingTimeout = Timer(const Duration(seconds: 2), () {
          if (!mounted || !_isWaitingForServer) return;
          _pollRoundState();
        });
      } else {
        _resetWaiting();
      }
    } catch (_) {
      // Server unreachable — retry if we haven't exhausted retries.
      if (_pollRetries < _maxPollRetries) {
        _waitingTimeout = Timer(const Duration(seconds: 2), () {
          if (!mounted || !_isWaitingForServer) return;
          _pollRoundState();
        });
      } else {
        _resetWaiting();
      }
    }
  }

  void _resetWaiting() {
    _waitingTimeout?.cancel();
    _pollRetries = 0;
    if (mounted) {
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
          MaterialPageRoute(
            builder: (_) => ConnectionLostScreen(
              onReconnect: () {
                Navigator.of(context).pop();
                _connectWebSocket();
              },
              onExit: () {
                // Use go_router to navigate to main menu — popUntil
                // doesn't work reliably with go_router's route stack.
                if (mounted) GoRouter.of(context).go('/main');
              },
            ),
          ),
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

  // ── Rematch methods ──────────────────────────────────────
  void _requestRematch() async {
    setState(() {
      _isRematchWaiting = true;
      _showRematchRequest = false;
    });
    try {
      await _authClient.post('/matches/${widget.matchId}/rematch/request');
      _startRematchPolling();

      // F5: 30-second timeout for rematch request
      _rematchCountdown?.cancel();
      int remaining = 30;
      _rematchCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        remaining--;
        if (remaining <= 0) {
          timer.cancel();
          _rematchPollTimer?.cancel();
          setState(() => _isRematchWaiting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rematch request timed out.')),
            );
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      final serverMsg = (e is DioException && e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)['error'] as String?
          : null;
      setState(() => _isRematchWaiting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(serverMsg ?? 'Rematch request failed. Please try again.')));
      }
    }
  }

  void _acceptRematch() async {
    _rematchCountdown?.cancel();
    _rematchPollTimer?.cancel();
    try {
      final res = await _authClient.post('/matches/${widget.matchId}/rematch/accept');
      final data = res.data as Map<String, dynamic>;
      final newMatchId = (data['newMatchId'] as num?)?.toInt();
      if (!mounted) return;

      if (newMatchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rematch accepted, but no match id returned.')));
        return;
      }

      GoRouter.of(context).pushReplacement('/online-gameplay', extra: {
        'matchId': newMatchId,
        'playerName': widget.playerName,
        'opponentName': widget.opponentName,
      });
    } catch (e) {
      if (!mounted) return;
      final serverMsg = (e is DioException && e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)['error'] as String?
          : null;
      setState(() {
        _showRematchRequest = false;
        _isRematchWaiting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(serverMsg ?? 'Failed to accept rematch. Please try again.')));
      }
    }
  }

  void _declineRematch() async {
    _rematchCountdown?.cancel();
    _rematchPollTimer?.cancel();
    setState(() {
      _showRematchRequest = false;
      _isRematchWaiting = false;
    });
    try {
      await _authClient.post('/matches/${widget.matchId}/rematch/decline');
    } catch (_) {
      // Decline failed — best-effort
    }
  }

  void _handleRematchAccepted(Map<String, dynamic> data) {
    _rematchCountdown?.cancel();
    _rematchPollTimer?.cancel();
    final newMatchId = (data['newMatchId'] as num?)?.toInt();
    if (!mounted || newMatchId == null) return;

    GoRouter.of(context).pushReplacement('/online-gameplay', extra: {
      'matchId': newMatchId,
      'playerName': widget.playerName,
      'opponentName': widget.opponentName,
    });
  }

  void _startRematchCountdown() {
    _rematchCountdown?.cancel();
    int remaining = 15;
    _rematchCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        _declineRematch();
      }
    });
  }

  void _startRematchPolling() {
    _rematchPollTimer?.cancel();
    _rematchPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || !_isRematchWaiting) {
        _rematchPollTimer?.cancel();
        return;
      }
      try {
        final res = await _authClient.get(
          '/matches/${widget.matchId}/state', // <--- Changed from '/rematch-status'
        );
        final data = res.data as Map<String, dynamic>;
        final status = data['rematchStatus'] as String?;
        final newMatchId = (data['newMatchId'] as num?)?.toInt();
        
        if (status == 'accepted' && newMatchId != null) {
          _rematchPollTimer?.cancel();
          if (!mounted) return;
          GoRouter.of(context).pushReplacement('/online-gameplay', extra: {
            'matchId': newMatchId,
            'playerName': widget.playerName,
            'opponentName': widget.opponentName,
          });
        } else if (status == 'declined') {
          _rematchPollTimer?.cancel();
          if (!mounted) return;
          setState(() => _isRematchWaiting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opponent declined the rematch.')),
            );
          }
        }
      } catch (_) {
        // Polling failed, will retry on next tick
      }
    });
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
                                fontSize: 32,
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
                            if (_waitingForNextRound && !_isWaitingForServer)
                              const Text(
                                'NEXT ROUND...',
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
                        playerAMove: _isPlayerA ? _serverPlayerAMove! : _serverPlayerBMove!,
                        playerBMove: _isPlayerA ? _serverPlayerBMove! : _serverPlayerAMove!,
                        handAssetFor: themeController.handAssetFor,
                        playerALabel: widget.playerName,
                        playerBLabel: widget.opponentName,
                        playerAAuto: _isPlayerA ? _serverPlayerAAuto : _serverPlayerBAuto,
                        playerBAuto: _isPlayerA ? _serverPlayerBAuto : _serverPlayerAAuto,
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _handImage(_selectedMove, isPlayer: true),
                              if (_isAutoMove)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AUTO',
                                    style: TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                          iconAsset: 'assets/icons/icon_rock.svg',
                          isSelected: _selectedMove == 'rock',
                          isDisabled: _hasPicked || _selectedMove != null || _isWaitingForServer || _waitingForNextRound,
                          onSelected: () => _selectMove('rock'),
                          frameColor: const Color(0xFFF97316),
                        ),
                        MoveButton(
                          move: 'paper',
                          iconAsset: 'assets/icons/icon_paper.svg',
                          isSelected: _selectedMove == 'paper',
                          isDisabled: _hasPicked || _selectedMove != null || _isWaitingForServer || _waitingForNextRound,
                          onSelected: () => _selectMove('paper'),
                          frameColor: const Color(0xFF06B6D4),
                        ),
                        MoveButton(
                          move: 'scissors',
                          iconAsset: 'assets/icons/icon_scissors.svg',
                          isSelected: _selectedMove == 'scissors',
                          isDisabled: _hasPicked || _selectedMove != null || _isWaitingForServer || _waitingForNextRound,
                          onSelected: () => _selectMove('scissors'),
                          frameColor: const Color(0xFFEC4899),
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
              if (_showResult) _buildResultOverlay(),
              if (_showRematchRequest) _buildRematchRequestOverlay(),
              if (_isRematchWaiting) _buildRematchWaitingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final playerWon = _playerScore > _opponentScore;
    final total = _playerScore + _opponentScore + _drawCount;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Victory/Defeat Card ───────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1.5,
                    color: (playerWon ? AppColors.green : AppColors.red)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      playerWon ? 'VICTORY' : 'DEFEAT',
                      style: TextStyle(
                        color: playerWon ? AppColors.green : AppColors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_playerScore - $_opponentScore',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isUnlimited) ...[
                      const SizedBox(height: 12),
                      Text(
                        '$total ROUNDS',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ── REMATCH button ────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestRematch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'REMATCH', // <--- Changed from 'PLAY AGAIN'
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── MAIN MENU button ──────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => GoRouter.of(context).go('/main'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'MAIN MENU',
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

  Widget _buildRematchRequestOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'OPPONENT WANTS A REMATCH',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${_rematchRequesterName ?? "Opponent"} is waiting...',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _acceptRematch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ACCEPT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _declineRematch,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'DECLINE',
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

  Widget _buildRematchWaitingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.defaultAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'WAITING FOR OPPONENT...',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _rematchCountdown?.cancel();
                    _rematchPollTimer?.cancel();
                    setState(() => _isRematchWaiting = false);
                  },
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