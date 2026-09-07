import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../../settings/settings_repository.dart';
import '../../stats/local_stats_repository.dart';
import '../domain/ai_service.dart';
import '../domain/match_engine.dart';
import '../domain/match_format.dart';
import '../widgets/countdown_animation.dart';
import '../widgets/draw_animation.dart';
import '../widgets/final_finish_animation.dart';
import '../widgets/round_victory_animation.dart';
import '../widgets/theme_background.dart';
import 'local_player_move_screen.dart';
import 'standard_result_screen.dart';
import 'unlimited_result_screen.dart';

enum _SpFlowStage {
  countdown,
  playerMove,
  aiThinking,
  revealing,
  finishing,
  roundComplete,
}

class SinglePlayerMatchFlowScreen extends ConsumerStatefulWidget {
  final MatchFormatConfig format;
  final AiDifficulty difficulty;

  const SinglePlayerMatchFlowScreen({
    super.key,
    required this.format,
    required this.difficulty,
  });

  @override
  ConsumerState<SinglePlayerMatchFlowScreen> createState() =>
      _SinglePlayerMatchFlowScreenState();
}

class _SinglePlayerMatchFlowScreenState
    extends ConsumerState<SinglePlayerMatchFlowScreen> {
  late final MatchEngine _engine;
  final AiService _ai = AiService();
  final LocalStatsRepository _statsRepo = LocalStatsRepository();
  _SpFlowStage _stage = _SpFlowStage.countdown;
  Timer? _countdownTimer;
  bool _victoryAnimationsEnabled = true;

  /// Game-mode label shown on every in-game screen, e.g. "Easy - Best of 3".
  String get _modeLabel =>
      '${widget.difficulty.label} - ${widget.format.displayLabel}';

  TextStyle get _modeTextStyle => TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      );

  @override
  void initState() {
    super.initState();
    AudioService.instance.stopMusic();
    _engine = MatchEngine(widget.format);
    _startRound();
    _loadVictoryAnimationSetting();
  }

  Future<void> _loadVictoryAnimationSetting() async {
    final settings = await SettingsRepository().load();
    if (!mounted) return;
    setState(() {
      _victoryAnimationsEnabled = settings.victoryAnimationsEnabled;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    AudioService.instance.playMusic();
    super.dispose();
  }

  void _startRound() {
    _engine.startRound();
    _engine.beginCountdown();
    setState(() {
      _stage = _SpFlowStage.countdown;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final finished = _engine.tickCountdown();
      if (mounted) {
        setState(() {});
      }
      if (finished) {
        timer.cancel();
        _engine.beginSelection();
        if (mounted) {
          setState(() {
            _stage = _SpFlowStage.playerMove;
          });
        }
      }
    });
  }

  void _onPlayerMove(String move) {
    _engine.submitPlayerAMove(move);
    setState(() {
      _stage = _SpFlowStage.aiThinking;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final aiMove = _ai.getMove(widget.difficulty);
      _engine.submitPlayerBMove(aiMove);
      _ai.recordPlayerMove(move);
      _reveal();
    });
  }

  void _reveal() {
    _engine.lockSelections();
    _engine.reveal();
    _engine.resolveRound();
    VibrationService.instance.reveal();
    setState(() {
      _stage = _SpFlowStage.revealing;
    });
    if (_engine.playerAMove != null) {
      _statsRepo.recordMoveSelection(_engine.playerAMove!);
    }
    switch (_engine.lastResult) {
      case RoundResult.playerAWin:
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.won);
        VibrationService.instance.victory();
        break;
      case RoundResult.playerBWin:
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.lost);
        VibrationService.instance.defeat();
        break;
      case RoundResult.draw:
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.drew);
        VibrationService.instance.draw();
        break;
      case null:
        break;
    }
    final delay = (_isMatchWinningRound && _victoryAnimationsEnabled)
        ? const Duration(seconds: 3)
        : const Duration(seconds: 2);
    Future.delayed(delay, _advanceAfterReveal);
  }

  void _advanceAfterReveal() {
    if (!mounted) return;
    _engine.checkMatchCondition();
    if (_engine.matchFinished) {
      if (widget.format.isUnlimited) {
        _statsRepo.recordUnlimitedMatchResult(
          winner: _engine.matchWinner,
        );
        _statsRepo.recordLocalMatch(
          opponentName: 'AI Bot',
          mode: 'single_player',
          formatType: 'unlimited',
          result: _engine.matchWinner == 'A'
              ? 'win'
              : _engine.matchWinner == null
                  ? 'draw'
                  : 'loss',
        );
      } else {
        _statsRepo.recordStandardMatchResult(
          playerWon: _engine.matchWinner == 'A',
        );
        _statsRepo.recordLocalMatch(
          opponentName: 'AI Bot',
          mode: 'single_player',
          formatType: widget.format.format.name,
          result: _engine.matchWinner == 'A'
              ? 'win'
              : _engine.matchWinner == null
                  ? 'draw'
                  : 'loss',
        );
      }
      setState(() {
        _stage = _SpFlowStage.roundComplete;
      });
    } else {
      _startRound();
    }
  }

  bool get _isMatchWinningRound {
    if (widget.format.isUnlimited) return false;
    if (_engine.lastResult == RoundResult.playerAWin) {
      return widget.format.isMatchWon(_engine.playerAScore);
    }
    if (_engine.lastResult == RoundResult.playerBWin) {
      return widget.format.isMatchWon(_engine.playerBScore);
    }
    return false;
  }

  bool get _canEndMatchNow {
    if (!widget.format.isUnlimited) return false;
    if (_engine.totalRounds == 0) return false;
    return _stage == _SpFlowStage.countdown ||
        _stage == _SpFlowStage.playerMove;
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBackground(
      theme: ref.watch(gameThemeProvider),
      child: Stack(
        children: [
          _buildStageContent(),
          // ── Round number + game-mode label at the top center ──
          if (_stage != _SpFlowStage.roundComplete &&
              _stage != _SpFlowStage.finishing)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ROUND ${_engine.currentRoundNumber}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                    const SizedBox(height: 2),
                    Text(_modeLabel, style: _modeTextStyle),
                  ],
                ),
              ),
            ),
          if (_canEndMatchNow)
            Positioned(
              top: 48,
              right: 16,
              child: SafeArea(
                child: TextButton(
                  onPressed: _onEndMatchPressed,
                  child: const Text(
                    'END MATCH',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _SpFlowStage.countdown:
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CountdownAnimation(
              value: _engine.countdownValue,
              theme: ref.watch(gameThemeProvider),
            ),
          ),
        );

      case _SpFlowStage.playerMove:
        return LocalPlayerMoveScreen(
          playerNumber: 1,
          onMoveSelected: _onPlayerMove,
          modeLabel: _modeLabel,
        );

      case _SpFlowStage.aiThinking:
        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.defaultAccent,
            ),
          ),
        );

      case _SpFlowStage.revealing:
        final themeController = ref.read(gameThemeProvider.notifier);
        final playerAWon = _engine.lastResult == RoundResult.playerAWin;
        final roundKey = ValueKey(
          'sp_round_${_engine.currentRoundNumber}_${_engine.lastResult}',
        );
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ROUND ${_engine.currentRoundNumber}',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
                const SizedBox(height: 2),
                Text(_modeLabel, style: _modeTextStyle),
                const SizedBox(height: 16),
                if (_isMatchWinningRound &&
                    _victoryAnimationsEnabled &&
                    _engine.playerAMove != null &&
                    _engine.playerBMove != null)
                  FinalFinishAnimation(
                    key: roundKey,
                    playerAMove: _engine.playerAMove!,
                    playerBMove: _engine.playerBMove!,
                    playerAWon: playerAWon,
                    theme: ref.watch(gameThemeProvider),
                    handAssetFor: themeController.handAssetFor,
                  )
                else if (_isMatchWinningRound && !_victoryAnimationsEnabled)
                  const SizedBox.shrink()
                else if ((_engine.lastResult == RoundResult.playerAWin ||
                        _engine.lastResult == RoundResult.playerBWin) &&
                    _engine.playerAMove != null &&
                    _engine.playerBMove != null)
                  RoundVictoryAnimation(
                    key: roundKey,
                    playerAMove: _engine.playerAMove!,
                    playerBMove: _engine.playerBMove!,
                    playerAWon: playerAWon,
                    playerALabel: 'YOU',
                    playerBLabel: 'AI',
                    theme: ref.watch(gameThemeProvider),
                    handAssetFor: themeController.handAssetFor,
                  )
                else if (_engine.lastResult == RoundResult.draw &&
                    _engine.playerAMove != null &&
                    _engine.playerBMove != null)
                  DrawAnimation(
                    key: roundKey,
                    playerAMove: _engine.playerAMove!,
                    playerBMove: _engine.playerBMove!,
                    theme: ref.watch(gameThemeProvider),
                  )
                else
                  Text(
                    _resultLabel(),
                    style: const TextStyle(
                      color: AppColors.defaultAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );

      case _SpFlowStage.finishing:
        final themeController = ref.read(gameThemeProvider.notifier);
        final playerAWon = _engine.matchWinner == 'A';
        final playerAMove = _engine.playerAMove;
        final playerBMove = _engine.playerBMove;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: playerAMove != null && playerBMove != null
                ? FinalFinishAnimation(
                    key: ValueKey(
                      'sp_finish_${_engine.currentRoundNumber}_${_engine.matchWinner}',
                    ),
                    playerAMove: playerAMove,
                    playerBMove: playerBMove,
                    playerAWon: playerAWon,
                    theme: ref.watch(gameThemeProvider),
                    handAssetFor: themeController.handAssetFor,
                  )
                : const SizedBox.shrink(),
          ),
        );

      case _SpFlowStage.roundComplete:
        if (widget.format.isUnlimited) {
          return UnlimitedResultScreen(
            player1Wins: _engine.playerAScore,
            player2Wins: _engine.playerBScore,
            draws: _engine.drawCount,
            totalRounds: _engine.totalRounds,
            player1WinRate: _engine.playerAWinRate,
            player2WinRate: _engine.playerBWinRate,
            onPlayAgain: () => GoRouter.of(context).pop(),
            onMainMenu: () => GoRouter.of(context).go('/main'),
          );
        }
        final playerWon = _engine.matchWinner == 'A';
        return StandardResultScreen(
          playerWon: playerWon,
          playerScore: _engine.playerAScore,
          opponentScore: _engine.playerBScore,
          onPlayAgain: () => GoRouter.of(context).pop(),
          onMainMenu: () => GoRouter.of(context).go('/main'),
        );
    }
  }

  String _resultLabel() {
    switch (_engine.lastResult) {
      case RoundResult.playerAWin:
        return 'YOU WIN THE ROUND';
      case RoundResult.playerBWin:
        return 'AI WINS THE ROUND';
      case RoundResult.draw:
        return 'DRAW';
      case null:
        return '';
    }
  }

  void _onEndMatchPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'END MATCH?',
          style: TextStyle(
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'Current Score: ${_engine.playerAScore} - ${_engine.playerBScore}',
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _countdownTimer?.cancel();
              _engine.endUnlimitedMatch();
              _statsRepo.recordUnlimitedMatchResult(
                winner: _engine.matchWinner,
              );
              _statsRepo.recordLocalMatch(
                opponentName: 'AI Bot',
                mode: 'single_player',
                formatType: 'unlimited',
                result: _engine.matchWinner == 'A'
                    ? 'win'
                    : _engine.matchWinner == null
                        ? 'draw'
                        : 'loss',
              );
              if (_engine.matchWinner != null &&
                  _victoryAnimationsEnabled &&
                  _engine.playerAMove != null &&
                  _engine.playerBMove != null) {
                setState(() {
                  _stage = _SpFlowStage.finishing;
                });
                Future.delayed(const Duration(seconds: 3), () {
                  if (!mounted) return;
                  setState(() {
                    _stage = _SpFlowStage.roundComplete;
                  });
                });
              } else {
                setState(() {
                  _stage = _SpFlowStage.roundComplete;
                });
              }
            },
            child: const Text(
              'END MATCH',
              style: TextStyle(
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}