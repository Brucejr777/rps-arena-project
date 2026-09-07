import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/vibration_service.dart';
import '../../stats/local_stats_repository.dart';
import '../widgets/move_button.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  const TournamentScreen({super.key});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  // Tournament bracket: 8 players, 3 rounds (Quarter, Semi, Final)
  final List<String> _playerNames = [
    'You',
    'Shadow',
    'Blaze',
    'Storm',
    'Viper',
    'Phoenix',
    'Titan',
    'Nova'
  ];

  late List<String> _bracket;
  late List<String> _nextRound;
  int _currentRound = 0; // 0=QF, 1=SF, 2=F
  int _currentMatch = 0;
  bool _isMatchActive = false;
  String? _selectedMove;
  String? _lastResult;
  bool _showOpponentMove = false;
  String? _opponentMove;
  int _matchWins = 0;
  int _matchLosses = 0;
  bool _isTournamentComplete = false;
  String _tournamentWinner = '';

  // ── FIX: single shared repository instance for all stats calls ──
  final LocalStatsRepository _statsRepo = LocalStatsRepository();

  @override
  void initState() {
    super.initState();
    _bracket = List.from(_playerNames);
    _nextRound = [];
    _isMatchActive = true;
  }

  // ── FIX: record move selection + round outcome ──
  void _selectMove(String move) {
    if (!_isMatchActive) return;
    AudioService.instance.playSound('select');
    VibrationService.instance.selection();
    setState(() {
      _selectedMove = move;
      _isMatchActive = false;
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

      final result = _determineWinner(move, aiMove);
      setState(() {
        _lastResult = result;
      });

      // FIX: record the round outcome
      if (result.contains('You win')) {
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.won);
      } else if (result.contains('You lose')) {
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.lost);
      } else {
        _statsRepo.recordRoundOutcome(RoundOutcomeForStats.drew);
      }

      _advanceMatch(result.contains('You win'));
    });
  }

  String _getAIMove() {
    final moves = ['rock', 'paper', 'scissors'];
    moves.shuffle();
    return moves.first;
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

  void _advanceMatch(bool playerWon) {
    final winner = playerWon
        ? _bracket[_currentMatch * 2]
        : _bracket[_currentMatch * 2 + 1];
    _nextRound.add(winner);

    if (playerWon) {
      _matchWins++;
    } else {
      _matchLosses++;
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentMatch++;
      // Check if round is complete
      if (_currentMatch >= _bracket.length ~/ 2) {
        _advanceRound();
      } else {
        setState(() {
          _selectedMove = null;
          _opponentMove = null;
          _showOpponentMove = false;
          _lastResult = null;
          _isMatchActive = true;
        });
      }
    });
  }

  void _advanceRound() {
    _currentRound++;
    _bracket = List.from(_nextRound);
    _nextRound = [];
    _currentMatch = 0;

    if (_bracket.length == 1) {
      // Tournament complete
      setState(() {
        _isTournamentComplete = true;
        _tournamentWinner = _bracket[0];
      });
      _saveResult();
    } else {
      setState(() {
        _selectedMove = null;
        _opponentMove = null;
        _showOpponentMove = false;
        _lastResult = null;
        _isMatchActive = true;
      });
    }
  }

  // ── FIX: use shared _statsRepo instance ──
  void _saveResult() async {
    await _statsRepo.recordStandardMatchResult(
        playerWon: _bracket[0] == 'You');
  }

  void _playAgain() {
    setState(() {
      _bracket = List.from(_playerNames);
      _nextRound = [];
      _currentRound = 0;
      _currentMatch = 0;
      _matchWins = 0;
      _matchLosses = 0;
      _isMatchActive = true;
      _selectedMove = null;
      _lastResult = null;
      _opponentMove = null;
      _showOpponentMove = false;
      _isTournamentComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(appAccentColorProvider);

    if (_isTournamentComplete) {
      return _buildResultScreen(accent);
    }

    final roundNames = ['QUARTER-FINALS', 'SEMI-FINALS', 'FINALS'];
    final currentOpponent = _bracket[_currentMatch * 2 + 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                    'TOURNAMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),

              // Round info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentRound == 2
                          ? Icons.emoji_events
                          : Icons.sports_martial_arts,
                      color: accent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      roundNames[_currentRound],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Match info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent),
                          ),
                          child: const Center(
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface),
                          ),
                          child: Center(
                            child: Text(
                              currentOpponent[0],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentOpponent.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                    isSelected: _selectedMove == 'rock',
                    isDisabled: !_isMatchActive,
                    onSelected: () => _selectMove('rock'),
                    frameColor: AppColors.orange,
                  ),
                  MoveButton(
                    move: 'paper',
                    isSelected: _selectedMove == 'paper',
                    isDisabled: !_isMatchActive,
                    onSelected: () => _selectMove('paper'),
                    frameColor: AppColors.cyan,
                  ),
                  MoveButton(
                    move: 'scissors',
                    isSelected: _selectedMove == 'scissors',
                    isDisabled: !_isMatchActive,
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
    );
  }

  Widget _buildResultScreen(Color accent) {
    final won = _tournamentWinner == 'You';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: won ? Colors.amber : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                won ? 'CHAMPION!' : 'TOURNAMENT OVER',
                style: TextStyle(
                  color: won ? Colors.amber : Colors.red,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (won)
                const Text(
                  'You won the tournament!',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                )
              else
                Text(
                  '$_tournamentWinner won the tournament',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip('Wins', '$_matchWins', AppColors.green),
                  const SizedBox(width: 16),
                  _buildStatChip('Losses', '$_matchLosses', AppColors.red),
                ],
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}