import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/animation_speed_controller.dart';
import 'theme_background.dart'; // ADDED – defines GameTheme

class RoundVictoryAnimation extends ConsumerStatefulWidget {
  final String playerAMove;
  final String playerBMove;
  final bool playerAWon;
  final String playerALabel;
  final String playerBLabel;
  final GameTheme theme;
  final String Function(String move) handAssetFor;
  final String? resultText; // custom result text

  const RoundVictoryAnimation({
    super.key,
    required this.playerAMove,
    required this.playerBMove,
    required this.playerAWon,
    this.playerALabel = 'PLAYER 1',
    this.playerBLabel = 'PLAYER 2',
    required this.theme,
    required this.handAssetFor,
    this.resultText,
  });

  @override
  ConsumerState<RoundVictoryAnimation> createState() =>
      _RoundVictoryAnimationState();
}

class _RoundVictoryAnimationState extends ConsumerState<RoundVictoryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _winnerScale;
  late Animation<double> _loserSlide;
  late Animation<double> _loserOpacity;

  @override
  void initState() {
    super.initState();
    final speedMultiplier = ref.read(animationSpeedProvider);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (2000 * speedMultiplier).round(),
      ),
    );

    _winnerScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.1)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    _loserSlide = Tween<double>(begin: 0, end: 40).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _loserOpacity = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _glowColor => widget.theme == GameTheme.space
      ? AppColors.secondaryAccent
      : AppColors.green;

  String get _winnerLabel =>
      widget.playerAWon ? widget.playerALabel : widget.playerBLabel;

  Widget _buildHand({
    required String move,
    required bool isWinner,
    required String label,
    required bool isLeftSide,
  }) {
    if (isWinner) {
      return Transform.scale(
        scale: _winnerScale.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withValues(alpha: 0.7),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                widget.handAssetFor(move),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: _glowColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      final slideDirection = isLeftSide ? -1.0 : 1.0;
      return Opacity(
        opacity: _loserOpacity.value,
        child: Transform.translate(
          offset: Offset(_loserSlide.value * slideDirection, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  widget.handAssetFor(move),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHand(
                  move: widget.playerAMove,
                  isWinner: widget.playerAWon,
                  label: widget.playerALabel,
                  isLeftSide: true,
                ),
                _buildHand(
                  move: widget.playerBMove,
                  isWinner: !widget.playerAWon,
                  label: widget.playerBLabel,
                  isLeftSide: false,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          widget.resultText ?? '$_winnerLabel WINS THE ROUND',
          style: TextStyle(
            color: _glowColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: _glowColor.withValues(alpha: 0.6), blurRadius: 16),
            ],
          ),
        ),
      ],
    );
  }
}