import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../../stats/local_stats_repository.dart';
import '../widgets/countdown_animation.dart';
import '../widgets/draw_animation.dart';
import '../widgets/local_scoreboard.dart';
import '../widgets/reveal_animation.dart';
import '../widgets/round_victory_animation.dart';
import '../widgets/theme_background.dart';
import 'local_player_move_screen.dart';
import 'standard_result_screen.dart';

/// Time Attack mode: 10 rounds, 3 seconds per move, random CPU.
///
/// Uses the same animation pipeline and themed hand assets as
/// Single Player and Local 2 Players for visual consistency.
enum _TaFlowStage {
  countdown,
  playerMove,
  aiThinking,
  revealing,
  roundComplete,
}

class TimeAttackScreen extends ConsumerStatefulWidget {
  const TimeAttackScreen({super.key});

  @override
  ConsumerState<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends ConsumerState<TimeAttackScreen> {
  static const int _totalRounds = 10;
  static const int _roundTimeLimit = 3;

  final LocalStatsRepository _statsRepo = LocalStatsRepository();
  final Random _random = Random();

  _TaFlowStage _stage = _TaFlowStage.countdown;

  int _currentRound = 1;
  int _playerScore = 0;
  int _aiScore = 0;
  int _drawCount = 0;
  int _timeRemaining = _roundTimeLimit;
  int _countdownValue = 3;

  String? _playerMove;
  String? _aiMove;
  /// 'player', 'ai', or 'draw'
  String? _lastResult;

  Timer? _countdownTimer;
  Timer? _selectionTimer;

  String get _modeLabel => 'TIME ATTACK';

  @override
  void initState() {
    super.initState();
    AudioService.instance.stopMusic();
    _startRound();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _selectionTimer?.cancel();
    AudioService.instance.playMusic();
    super.dispose();
  }

  // ── Round lifecycle ──────────────────────────────────────────

  void _startRound() {
    _playerMove = null;
    _aiMove = null;
    _lastResult = null;
    _timeRemaining = _roundTimeLimit;
    _countdownValue = 3;

    setState(() => _stage = _TaFlowStage.countdown);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      if (mounted) setState(() {});

      if (_countdownValue < 0) {
        timer.cancel();
        _beginSelection();
      }
    });
  }

  void _beginSelection() {
    if (!mounted) return;

    setState(() => _stage = _TaFlowStage.playerMove);

    _selectionTimer?.cancel();
    _selectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          timer.cancel();
          _onTimeout();
        }
      });
    });
  }

  void _onTimeout() {
    if (_playerMove != null) return;
    final autoMove = _randomMove();
    _onPlayerMove(autoMove);
  }

  void _onPlayerMove(String move) {
    _selectionTimer?.cancel();
    _playerMove = move;
    AudioService.instance.playTransition();

    setState(() => _stage = _TaFlowStage.aiThinking);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _aiMove = _randomMove();
      _statsRepo.recordMoveSelection(move);
      _reveal();
    });
  }

  Future<void> _reveal() async {
    final outcome = _resolve(_playerMove!, _aiMove!);
    _lastResult = outcome;

    AudioService.instance.playReveal();
    VibrationService.instance.reveal();

    setState(() => _stage = _TaFlowStage.revealing);

    switch (outcome) {
      case 'player':
        _playerScore++;
        AudioService.instance.playVictory();
        await _statsRepo.recordRoundOutcome(RoundOutcomeForStats.won);
        VibrationService.instance.victory();
        break;
      case 'ai':
        _aiScore++;
        AudioService.instance.playDefeat();
        await _statsRepo.recordRoundOutcome(RoundOutcomeForStats.lost);
        VibrationService.instance.defeat();
        break;
      case 'draw':
        _drawCount++;
        AudioService.instance.playDraw();
        await _statsRepo.recordRoundOutcome(RoundOutcomeForStats.drew);
        VibrationService.instance.draw();
        break;
    }

    Future.delayed(const Duration(seconds: 2), _advanceAfterReveal);
  }

  void _advanceAfterReveal() {
    if (!mounted) return;

    if (_currentRound >= _totalRounds) {
      _endGame();
    } else {
      _currentRound++;
      _startRound();
    }
  }

  Future<void> _endGame() async {
    await _statsRepo.recordStandardMatchResult(
      playerWon: _playerScore > _aiScore,
    );
    if (!mounted) return;
    setState(() => _stage = _TaFlowStage.roundComplete);
  }

  void _playAgain() {
    _currentRound = 1;
    _playerScore = 0;
    _aiScore = 0;
    _drawCount = 0;
    _startRound();
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _randomMove() =>
      ['rock', 'paper', 'scissors'][_random.nextInt(3)];

  String _resolve(String a, String b) {
    if (a == b) return 'draw';
    const beats = {
      'rock': 'scissors',
      'paper': 'rock',
      'scissors': 'paper',
    };
    return beats[a] == b ? 'player' : 'ai';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ThemeBackground(
      theme: ref.watch(gameThemeProvider),
      child: _buildStageContent(),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _TaFlowStage.countdown:
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 8),
                LocalScoreboard(
                  playerAScore: _playerScore,
                  playerBScore: _aiScore,
                  roundNumber: _currentRound,
                  draws: _drawCount,
                  modeLabel: _modeLabel,
                ),
                Expanded(
                  child: Center(
                    child: CountdownAnimation(
                      value: _countdownValue,
                      theme: ref.watch(gameThemeProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case _TaFlowStage.playerMove:
        // ── FIX: Timer is passed as centerWidget so it sits in the
        // flexible space between text and gesture cards — no overlap.
        // Exit button uses showBackButton: true (built-in) instead of
        // a separate Positioned overlay with SafeArea inside.
        return LocalPlayerMoveScreen(
          playerNumber: 1,
          onMoveSelected: _onPlayerMove,
          modeLabel: _modeLabel,
          roundNumber: _currentRound,
          showRoundLabel: true,
          showBackButton: true,
          centerWidget: _buildTimerDisplay(),
        );

      case _TaFlowStage.aiThinking:
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.defaultAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case _TaFlowStage.revealing:
        final themeController = ref.read(gameThemeProvider.notifier);
        final playerWon = _lastResult == 'player';
        final isDraw = _lastResult == 'draw';
        final roundKey = ValueKey(
          'ta_round_${_currentRound}_$_lastResult',
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 8),
                LocalScoreboard(
                  playerAScore: _playerScore,
                  playerBScore: _aiScore,
                  roundNumber: _currentRound,
                  draws: _drawCount,
                  modeLabel: _modeLabel,
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDraw &&
                              _playerMove != null &&
                              _aiMove != null)
                            DrawAnimation(
                              key: roundKey,
                              playerAMove: _playerMove!,
                              playerBMove: _aiMove!,
                              theme: ref.watch(gameThemeProvider),
                            )
                          else if (_playerMove != null &&
                              _aiMove != null)
                            RoundVictoryAnimation(
                              key: roundKey,
                              playerAMove: _playerMove!,
                              playerBMove: _aiMove!,
                              playerAWon: playerWon,
                              playerALabel: 'YOU',
                              playerBLabel: 'CPU',
                              theme: ref.watch(gameThemeProvider),
                              handAssetFor:
                                  themeController.handAssetFor,
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case _TaFlowStage.roundComplete:
        final isDraw = _playerScore == _aiScore;
        return StandardResultScreen(
          playerWon: _playerScore > _aiScore,
          playerScore: _playerScore,
          opponentScore: _aiScore,
          resultTitle: isDraw
              ? 'DRAW'
              : _playerScore > _aiScore
                  ? 'VICTORY'
                  : 'DEFEAT',
          resultColor: isDraw
              ? AppColors.orange
              : _playerScore > _aiScore
                  ? AppColors.green
                  : AppColors.red,
          showMatchWon: !isDraw && _playerScore > _aiScore,
          onPlayAgain: _playAgain,
          onMainMenu: () => GoRouter.of(context).go('/main'),
        );
    }
  }

  // ── Shared widgets ───────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.5,
                  color: AppColors.blue,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ROUND $_currentRound/$_totalRounds',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black87,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _modeLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final isWarning = _timeRemaining <= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.withValues(alpha: 0.2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1.5,
          color: isWarning
              ? Colors.red
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isWarning ? Colors.red : Colors.white,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            '$_timeRemaining',
            style: TextStyle(
              color: isWarning ? Colors.red : Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}