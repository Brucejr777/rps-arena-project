import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'theme_background.dart';

class DrawAnimation extends StatefulWidget {
  final String playerAMove;
  final String playerBMove;
  final GameTheme theme;

  const DrawAnimation({
    super.key,
    required this.playerAMove,
    required this.playerBMove,
    required this.theme,
  });

  @override
  State<DrawAnimation> createState() => _DrawAnimationState();
}

class _DrawAnimationState extends State<DrawAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // ~1.5 seconds
    );

    // Both hands perform a short reaction — a gentle side-to-side shake,
    // suggesting a "standoff" rather than a clear winner.
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.theme == GameTheme.space ? AppColors.secondaryAccent : Colors.white54;

  String get _movePairText =>
      '${widget.playerAMove.toUpperCase()} vs ${widget.playerBMove.toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shake.value, 0),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _movePairText,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'DRAW',
            style: TextStyle(
              color: _accentColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          // Note: score display is intentionally omitted here — a draw
          // never changes the score, so the parent screen's existing
          // score display remains visibly unchanged, reinforcing
          // "score unchanged" from the spec.
        ],
      ),
    );
  }
}