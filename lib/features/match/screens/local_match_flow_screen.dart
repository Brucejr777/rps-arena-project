import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/match_engine.dart';
import '../domain/match_format.dart';
import 'local_player_move_screen.dart';
import 'pass_device_screen.dart';
import 'standard_result_screen.dart';
import 'unlimited_result_screen.dart';
import '../../stats/local_stats_repository.dart';
import '../widgets/countdown_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/game_theme_controller.dart';
import '../widgets/theme_background.dart';
import '../widgets/reveal_animation.dart';
import '../widgets/round_victory_animation.dart';
import '../widgets/final_finish_animation.dart';
import '../widgets/draw_animation.dart';

enum _LocalFlowStage {
  countdown,
  playerOneMove,
  passDevice,
  playerTwoMove,
  revealing,
  finishing,
  roundComplete,
}

class LocalMatchFlowScreen extends ConsumerStatefulWidget {
  final MatchFormatConfig format;

  const LocalMatchFlowScreen({super.key, required this.format});

  @override
  ConsumerState<LocalMatchFlowScreen> createState() =>
      _LocalMatchFlowScreenState();
}

class _LocalMatchFlowScreenState
    extends ConsumerState<LocalMatchFlowScreen> {
  late final MatchEngine _engine;
  final LocalStatsRepository _statsRepo = LocalStatsRepository();
  _LocalFlowStage _stage = _LocalFlowStage.countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _engine = MatchEngine(widget.format);
    _startRound();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _engine.startRound();
    _engine.beginCountdown();
    setState(() => _stage = _LocalFlowStage.countdown);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final finished = _engine.tickCountdown();
      setState(() {}); // refresh countdown number on screen
      if (finished) {
        timer.cancel();
        _engine.beginSelection();
        setState(() => _stage = _LocalFlowStage.playerOneMove);
      }
    });
  }

  void _onPlayerOneMove(String move) {
    _engine.submitPlayerAMove(move);
    setState(() => _stage = _LocalFlowStage.passDevice);
  }

  void _onReady() {
    setState(() => _stage = _LocalFlowStage.playerTwoMove);
  }

  void _onPlayerTwoMove(String move) {
    _engine.submitPlayerBMove(move);
    _reveal();
  }

  void _reveal() {
    _engine.lockSelections();
    _engine.reveal();
    _engine.resolveRound();
    setState(() => _stage = _LocalFlowStage.revealing);

    if (_engine.playerAMove != null) {
      _statsRepo.recordMoveSelection(_engine.playerAMove!);
    }
    switch (_engine.lastResult) {
      case RoundResult.playerAWin:
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.won);
        break;
      case RoundResult.playerBWin:
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.lost);
        break;
      case RoundResult.draw:
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.drew);
        break;
      case null:
        break;
    }

    final delay = _isMatchWinningRound
        ? const Duration(seconds: 3)
        : const Duration(seconds: 2);
    Future.delayed(delay, _advanceAfterReveal);
  }

  void _advanceAfterReveal() {
    if (!mounted) return;
    _engine.checkMatchCondition();

    if (_engine.matchFinished) {
      if (widget.format.isUnlimited) {
        _statsRepo.recordUnlimitedMatchResult(winner: _engine.matchWinner);
      } else {
        _statsRepo.recordStandardMatchResult(
            playerWon: _engine.matchWinner == 'A');
      }
      setState(() => _stage = _LocalFlowStage.roundComplete);
    } else {
      _startRound();
    }
  }

  /// True only when this round's result would finish a standard match
/// (i.e. the winning player has now reached winsRequired).
  bool get _isMatchWinningRound {
    if (widget.format.isUnlimited) return false; // Unlimited never auto-finishes
    if (_engine.lastResult == RoundResult.playerAWin) {
      return widget.format.isMatchWon(_engine.playerAScore);
    }
    if (_engine.lastResult == RoundResult.playerBWin) {
      return widget.format.isMatchWon(_engine.playerBScore);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBackground(
      theme: ref.watch(gameThemeProvider),
      child: Stack(
        children: [
          _buildStageContent(),
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
        case _LocalFlowStage.countdown:
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CountdownAnimation(
                value: _engine.countdownValue,
                theme: ref.watch(gameThemeProvider),
              ),
            ),
          );

        case _LocalFlowStage.playerOneMove:
          return LocalPlayerMoveScreen(
            playerNumber: 1,
            onMoveSelected: _onPlayerOneMove,
          );

        case _LocalFlowStage.passDevice:
          return PassDeviceScreen(onReady: _onReady);

        case _LocalFlowStage.playerTwoMove:
          return LocalPlayerMoveScreen(
            playerNumber: 2,
            onMoveSelected: _onPlayerTwoMove,
          );

        case _LocalFlowStage.revealing:
          final themeController = ref.read(gameThemeProvider.notifier);
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'BOTH PLAYERS READY',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_engine.playerAMove != null && _engine.playerBMove != null)
                    RevealAnimation(
                      playerAMove: _engine.playerAMove!,
                      playerBMove: _engine.playerBMove!,
                      handAssetFor: themeController.handAssetFor,
                    ),
                  const SizedBox(height: 24),
                  if (_isMatchWinningRound)
                    FinalFinishAnimation(
                      winningMove: _engine.lastResult == RoundResult.playerAWin
                          ? _engine.playerAMove!
                          : _engine.playerBMove!,
                      losingMove: _engine.lastResult == RoundResult.playerAWin
                          ? _engine.playerBMove!
                          : _engine.playerAMove!,
                      theme: ref.watch(gameThemeProvider),
                      handAssetFor: themeController.handAssetFor,
                    )
                  else if (_engine.lastResult == RoundResult.draw &&
                      _engine.playerAMove != null && _engine.playerBMove != null)
                    DrawAnimation(
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

        case _LocalFlowStage.roundComplete:
          if (widget.format.isUnlimited) {
            return UnlimitedResultScreen(
              player1Wins: _engine.playerAScore,
              player2Wins: _engine.playerBScore,
              draws: _engine.drawCount,
              totalRounds: _engine.totalRounds,
              player1WinRate: _engine.playerAWinRate,
              player2WinRate: _engine.playerBWinRate,
              onPlayAgain: () => Navigator.of(context).maybePop(),
              onMainMenu: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            );
          }
          final playerWon = _engine.matchWinner == 'A';
          return StandardResultScreen(
            playerWon: playerWon,
            playerScore: _engine.playerAScore,
            opponentScore: _engine.playerBScore,
            onPlayAgain: () => Navigator.of(context).maybePop(),
            onMainMenu: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          );

        case _LocalFlowStage.finishing:
          final themeController = ref.read(gameThemeProvider.notifier);
          final winningMove =
              _engine.matchWinner == 'A' ? _engine.playerAMove : _engine.playerBMove;
          final losingMove =
              _engine.matchWinner == 'A' ? _engine.playerBMove : _engine.playerAMove;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: (winningMove != null && losingMove != null)
                  ? FinalFinishAnimation(
                      winningMove: winningMove,
                      losingMove: losingMove,
                      theme: ref.watch(gameThemeProvider),
                      handAssetFor: themeController.handAssetFor,
                    )
                  : const SizedBox.shrink(),
            ),
          );
      }
    }

    String _resultLabel() {
      switch (_engine.lastResult) {
        case RoundResult.playerAWin:
          return 'PLAYER 1 WINS THE ROUND';
        case RoundResult.playerBWin:
          return 'PLAYER 2 WINS THE ROUND';
        case RoundResult.draw:
          return 'DRAW — REPLAYING${widget.format.isUnlimited ? '' : ' ROUND'}';
        case null:
          return '';
      }
    }

    void _onEndMatchPressed() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('END MATCH?',
              style: TextStyle(color: AppColors.primaryText)),
          content: Text(
            'Current Score: ${_engine.playerAScore} - ${_engine.playerBScore}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _countdownTimer?.cancel();
                _engine.endUnlimitedMatch();
                _statsRepo.recordUnlimitedMatchResult(winner: _engine.matchWinner);

                if (_engine.matchWinner != null) {
                  setState(() => _stage = _LocalFlowStage.finishing);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() => _stage = _LocalFlowStage.roundComplete);
                    }
                  });
                } else {
                  setState(() => _stage = _LocalFlowStage.roundComplete);
                }
              },
              child: const Text('END MATCH',
                  style: TextStyle(color: AppColors.red)),
            ),
          ],
        ),
      );
    }

    bool get _canEndMatchNow {
      if (!widget.format.isUnlimited) return false;
      if (_engine.totalRounds == 0) return false;
      return _stage == _LocalFlowStage.countdown ||
          _stage == _LocalFlowStage.playerOneMove;
    }
  }