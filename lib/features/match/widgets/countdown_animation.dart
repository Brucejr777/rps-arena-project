import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/audio_service.dart';
import 'theme_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/animation_speed_controller.dart';

class CountdownAnimation extends ConsumerStatefulWidget {
  final int value;
  final GameTheme theme;

  const CountdownAnimation({
    super.key,
    required this.value,
    this.theme = GameTheme.normal,
  });

  @override
  ConsumerState<CountdownAnimation> createState() => _CountdownAnimationState();
}

class _CountdownAnimationState extends ConsumerState<CountdownAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    final speedMultiplier = ref.read(animationSpeedProvider);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (1000 * speedMultiplier).round(),
      ),
    );
    _setupAnimation();
    _controller.forward();
    // Link the countdown mp3 to each countdown tick.
    AudioService.instance.playCountdown();
  }

  void _setupAnimation() {
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
      _controller.reset();
      _controller.forward();
      // Play the countdown sound on every value change (3, 2, 1, GO!).
      AudioService.instance.playCountdown();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayText => widget.value == 0 ? 'GO!' : '${widget.value}';

  Color get _accentColor {
    if (widget.value == 0) return AppColors.green;
    return widget.theme == GameTheme.space
        ? AppColors.secondaryAccent // purple, matches Space theme
        : AppColors.primaryText; // Normal theme stays clean white
  }

  Color get _glowColor {
    return widget.theme == GameTheme.space
        ? AppColors.secondaryAccent
        : AppColors.defaultAccent;
  }

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
                color: _accentColor,
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: _glowColor.withValues(alpha: 0.6),
                    blurRadius: widget.theme == GameTheme.space ? 32 : 24,
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