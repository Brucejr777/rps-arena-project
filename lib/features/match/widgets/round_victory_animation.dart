import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'theme_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/animation_speed_controller.dart';


class RoundVictoryAnimation extends ConsumerStatefulWidget  {
  final String winningMove;
  final String losingMove;
  final GameTheme theme;
  final String Function(String move) handAssetFor;

  const RoundVictoryAnimation({
    super.key,
    required this.winningMove,
    required this.losingMove,
    required this.theme,
    required this.handAssetFor,
  });

  @override
  ConsumerState<RoundVictoryAnimation> createState() => _RoundVictoryAnimationState();
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
    ),// maximum duration two seconds
    );

    // Winning hand performs a themed "impact" — a confident pop/pulse.
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

    // Losing hand gets knocked backward and fades — "short defeat reaction".
    _loserSlide = Tween<double>(begin: 0, end: 40)
        .animate(CurvedAnimation(
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

  Color get _glowColor =>
      widget.theme == GameTheme.space ? AppColors.secondaryAccent : AppColors.green;

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
                // Winning hand
                Transform.scale(
                  scale: _winnerScale.value,
                  child: Container(
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
                      widget.handAssetFor(widget.winningMove),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Losing hand
                Opacity(
                  opacity: _loserOpacity.value,
                  child: Transform.translate(
                    offset: Offset(_loserSlide.value, 0),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        widget.handAssetFor(widget.losingMove),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'ROUND WON',
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