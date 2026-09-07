import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'theme_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/animation_speed_controller.dart';

class FinalFinishAnimation extends ConsumerStatefulWidget {
  final String playerAMove;
  final String playerBMove;
  final bool playerAWon;
  final GameTheme theme;
  final String Function(String move) handAssetFor;

  const FinalFinishAnimation({
    super.key,
    required this.playerAMove,
    required this.playerBMove,
    required this.playerAWon,
    required this.theme,
    required this.handAssetFor,
  });

  @override
  ConsumerState<FinalFinishAnimation> createState() =>
      _FinalFinishAnimationState();
}

class _FinalFinishAnimationState extends ConsumerState<FinalFinishAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _winnerScale;
  late Animation<double> _winnerRotation;
  late Animation<double> _loserSlide;
  late Animation<double> _loserOpacity;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    final speedMultiplier = ref.read(animationSpeedProvider);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (3000 * speedMultiplier).round(),
      ), // maximum duration three seconds
    );

    // Winner: "stylized impact" (Normal) / "energy attack" (Space)
    _winnerScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 75,
      ),
    ]).animate(_controller);

    _winnerRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 75),
    ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Loser: "knocked backward" / "powers down"
    _loserSlide = Tween<double>(begin: 0, end: 80).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _loserOpacity = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Continuous soft glow pulse behind the winner
    _glowPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.4), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _glowColor => widget.theme == GameTheme.space
      ? AppColors.secondaryAccent
      : AppColors.defaultAccent;

  /// Builds a single hand with winner or loser styling.
  Widget _buildHand({
    required String move,
    required bool isWinner,
  }) {
    if (isWinner) {
      return Transform.rotate(
        angle: _winnerRotation.value,
        child: Transform.scale(
          scale: _winnerScale.value,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _glowColor.withValues(alpha: _glowPulse.value),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              widget.handAssetFor(move),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else {
      // Loser slides AWAY from centre and fades
      final slideDirection = widget.playerAWon ? 1.0 : -1.0;
      return Opacity(
        opacity: _loserOpacity.value,
        child: Transform.translate(
          offset: Offset(_loserSlide.value * slideDirection, 0),
          child: Container(
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // LEFT slot — always Player A
            _buildHand(
              move: widget.playerAMove,
              isWinner: widget.playerAWon,
            ),
            // RIGHT slot — always Player B / AI
            _buildHand(
              move: widget.playerBMove,
              isWinner: !widget.playerAWon,
            ),
          ],
        );
      },
    );
  }
}