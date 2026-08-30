import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/match_engine.dart';
import '../domain/match_format.dart';
import '../domain/resolution.dart';
import 'local_player_move_screen.dart';
import 'pass_device_screen.dart';

enum _LocalFlowStage { playerOneMove, passDevice, playerTwoMove, revealing }

class LocalMatchFlowScreen extends StatefulWidget {
  final MatchFormatConfig format;

  const LocalMatchFlowScreen({super.key, required this.format});

  @override
  State<LocalMatchFlowScreen> createState() => _LocalMatchFlowScreenState();
}

class _LocalMatchFlowScreenState extends State<LocalMatchFlowScreen> {
  late final MatchEngine _engine;
  _LocalFlowStage _stage = _LocalFlowStage.playerOneMove;

  @override
  void initState() {
    super.initState();
    _engine = MatchEngine(widget.format);
    _engine.startRound();
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
    setState(() => _stage = _LocalFlowStage.revealing);
    _reveal();
  }

  void _reveal() {
    // "after Player 2 selection, display BOTH PLAYERS READY,
    // reveal both selections simultaneously, calculate result
    // using core resolution"
    _engine.reveal();
    _engine.resolveRound();
    // Result is now available via _engine.lastResult, playerAScore, etc.
    // T45/T46/T48/T49 wire this into full match progression + result screens.
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
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
                const SizedBox(height: 24),
                Text(
                  _resultLabel(),
                  style: const TextStyle(
                    color: AppColors.defaultAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
        return 'DRAW';
      case null:
        return '';
    }
  }
}