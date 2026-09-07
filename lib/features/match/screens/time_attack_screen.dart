import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../stats/local_stats_repository.dart';
import '../widgets/move_button.dart';
import '../widgets/pause_exit_overlay.dart';

class TimeAttackScreen extends ConsumerStatefulWidget {
  const TimeAttackScreen({super.key});

  @override
  ConsumerState<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends ConsumerState<TimeAttackScreen> {
  int _currentRound = 1;
  final int _totalRounds = 10;
  int _playerScore = 0;
  int _aiScore = 0;
  String? _selectedMove;
  String? _lastResult;
  bool _isRoundActive = true;
  bool _isPaused = false;
  bool _isGameComplete = false;

  // Time attack specific — CHANGED: 30 → 3 seconds
  static const int _roundTimeLimit = 3;
  int _timeRemaining = _roundTimeLimit;
  Timer? _timer;

  // Animation
  String? _opponentMove;
  bool _showOpponentMove = false;

  // ── FIX: single shared repository instance for all stats calls ──
  final LocalStatsRepository _statsRepo = LocalStatsRepository();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          _timer?.cancel();
          _timeOut();
        }
      });
    });
  }

  // ── FIX: record round-outcome as lost on timeout ──
  void _timeOut() {
    if (!_isRoundActive) return;
    setState(() {
      _isRoundActive = false;
      _opponentMove = _getAIMove();
      _showOpponentMove = true;
      _lastResult = 'TIME UP! You took too long.';
      _aiScore++;
    });
    // FIX: record the timeout as a lost round
    _statsRepo.recordRoundOutcome(RoundOutcomeForStats.lost);
    _nextRoundAfterDelay();
  }

  String _getAIMove() {
    final moves = ['rock', 'paper', 'scissors'];
    moves.shuffle();
    return moves.first;
  }

  // ── FIX: made async; record move selection + round outcome ──
  void _selectMove(String move) {
    if (!_isRoundActive || _isPaused) return;
    _timer?.cancel();
    AudioService.instance.playSound('select');
    VibrationService.instance.selection();
    setState(() {
      _selectedMove = move;
      _isRoundActive = false;
    });

    // FIX: record the player's move selection immediately
    _statsRepo.recordMoveSelection(move);

    // AI makes move
    Future.delayed(const Duration(milliseconds: 500), () {
      final aiMove = _getAIMove();
      setState(() {
        _opponentMove = aiMove;
        _showOpponentMove = true;
      });

      // Determine winner
      final result = _determineWinner(move, aiMove);
      setState(() {
        _lastResult = result;
        if (result.contains('You win')) {
          _playerScore++;
        } else if (result.contains('You lose')) {
          _aiScore++;
        }
      });

      // FIX: record the round outcome
      if (result.contains('You win')) {
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.won);
      } else if (result.contains('You lose')) {
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.lost);
      } else {
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.drew);
      }

      _nextRoundAfterDelay();
    });
  }

  String _determineWinner(String playerMove, String aiMove) {
    if (playerMove == aiMove) return 'DRAW!';
    if ((playerMove == 'rock' && aiMove == 'scissors') ||
        (playerMove == 'paper' && aiMove == 'rock') ||
        (playerMove == 'scissors' && aiMove == 'paper')) {
      return 'You win this round!';
    }
    return 'You lose this round!';
  }

  void _nextRoundAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentRound >= _totalRounds) {
        _endGame();
      } else {
        setState(() {
          _currentRound++;
          _selectedMove = null;
          _opponentMove = null;
          _showOpponentMove = false;
          _lastResult = null;
          _isRoundActive = true;
          _timeRemaining = _roundTimeLimit; // CHANGED: uses constant
        });
        _startTimer();
      }
    });
  }

  void _endGame() {
    setState(() {
      _isGameComplete = true;
    });
    _saveResult();
  }

  // ── FIX: use shared _statsRepo instance ──
  void _saveResult() async {
    await _statsRepo.recordStandardMatchResult(
        playerWon: _playerScore > _aiScore);
  }

  void _playAgain() {
    setState(() {
      _currentRound = 1;
      _playerScore = 0;
      _aiScore = 0;
      _selectedMove = null;
      _lastResult = null;
      _opponentMove = null;
      _showOpponentMove = false;
      _isRoundActive = true;
      _isGameComplete = false;
      _timeRemaining = _roundTimeLimit; // CHANGED: uses constant
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(appAccentColorProvider);

    if (_isGameComplete) {
      return _buildResultScreen(accent);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/single-player-setup'),
                      ),
                      const Spacer(),
                      const Text(
                        'TIME ATTACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.pause, color: Colors.white),
                        onPressed: () {
                          _timer?.cancel();
                          setState(() => _isPaused = true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Timer — CHANGED: warning threshold from <= 10 to <= 1
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 1
                          ? Colors.red.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _timeRemaining <= 1
                            ? Colors.red
                            : AppColors.surface,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _timeRemaining <= 1
                              ? Colors.red
                              : Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_timeRemaining',
                          style: TextStyle(
                            color: _timeRemaining <= 1
                                ? Colors.red
                                : Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Round $_currentRound/$_totalRounds',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreCard('YOU', _playerScore, AppColors.green),
                      _buildScoreCard('CPU', _aiScore, AppColors.red),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Result display
                  if (_lastResult != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lastResult!.contains('win')
                            ? AppColors.green.withValues(alpha: 0.2)
                            : _lastResult!.contains('lose')
                                ? AppColors.red.withValues(alpha: 0.2)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lastResult!.contains('win')
                              ? AppColors.green
                              : _lastResult!.contains('lose')
                                  ? AppColors.red
                                  : AppColors.surface,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_showOpponentMove && _opponentMove != null) ...[
                            Icon(
                              _opponentMove == 'rock'
                                  ? Icons.circle
                                  : _opponentMove == 'paper'
                                      ? Icons.square
                                      : Icons.content_cut,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            _lastResult!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Move buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MoveButton(
                        move: 'rock',
                        iconAsset: 'assets/icons/icon_rock.svg',
                        isSelected: _selectedMove == 'rock',
                        isDisabled: !_isRoundActive,
                        onSelected: () => _selectMove('rock'),
                        frameColor: AppColors.orange,
                      ),
                      MoveButton(
                        move: 'paper',
                        iconAsset: 'assets/icons/icon_paper.svg',
                        isSelected: _selectedMove == 'paper',
                        isDisabled: !_isRoundActive,
                        onSelected: () => _selectMove('paper'),
                        frameColor: AppColors.cyan,
                      ),
                      MoveButton(
                        move: 'scissors',
                        iconAsset: 'assets/icons/icon_scissors.svg',
                        isSelected: _selectedMove == 'scissors',
                        isDisabled: !_isRoundActive,
                        onSelected: () => _selectMove('scissors'),
                        frameColor: AppColors.magenta,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isPaused)
            PauseExitOverlay(
              onResume: () {
                setState(() => _isPaused = false);
                _startTimer();
              },
              onExit: () => context.go('/single-player-setup'),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen(Color accent) {
    final won = _playerScore > _aiScore;
    final draw = _playerScore == _aiScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                won
                    ? Icons.emoji_events
                    : draw
                        ? Icons.handshake
                        : Icons.sentiment_dissatisfied,
                color: won ? Colors.amber : draw ? Colors.white70 : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                draw ? 'DRAW!' : won ? 'YOU WIN!' : 'YOU LOSE!',
                style: TextStyle(
                  color: won ? Colors.amber : draw ? Colors.white : Colors.red,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_playerScore - $_aiScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Time Attack Complete',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _playAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19.5),
                    ),
                  ),
                  child: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/single-player-setup'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.surface),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19.5),
                    ),
                  ),
                  child: const Text(
                    'BACK TO SETUP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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