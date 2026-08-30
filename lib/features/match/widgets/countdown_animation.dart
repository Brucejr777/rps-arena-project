import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CountdownAnimation extends StatefulWidget {
  /// 3, 2, 1, or 0 (0 means "GO!")
  final int value;

  const CountdownAnimation({super.key, required this.value});

  @override
  State<CountdownAnimation> createState() => _CountdownAnimationState();
}

class _CountdownAnimationState extends State<CountdownAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _setupAnimation();
    _controller.forward();
  }

  void _setupAnimation() {
    // scale 80% -> 120% -> 0% across the one-second duration
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant CountdownAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // Restart the animation for the new number/GO!
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayText => widget.value == 0 ? 'GO!' : '${widget.value}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Text(
              _displayText,
              style: TextStyle(
                color: widget.value == 0
                    ? AppColors.green
                    : AppColors.primaryText,
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: AppColors.defaultAccent.withValues(alpha: 0.6),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}