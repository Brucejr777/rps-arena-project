import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/animation_speed_controller.dart';

class RevealAnimation extends ConsumerStatefulWidget  {
  final String playerAMove;
  final String playerBMove;
  final String Function(String move) handAssetFor;
  final String playerALabel;
  final String playerBLabel;


  const RevealAnimation({
    super.key,
    required this.playerAMove,
    required this.playerBMove,
    required this.handAssetFor,
    this.playerALabel = 'PLAYER 1',
    this.playerBLabel = 'PLAYER 2',
  });

  @override
  ConsumerState<RevealAnimation> createState() => _RevealAnimationState();
}

class _RevealAnimationState extends ConsumerState<RevealAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
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
    _slideAnimation = Tween<double>(begin: 60, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _hand(String move, {required bool fromLeft, required String label}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = fromLeft ? _slideAnimation.value : -_slideAnimation.value;
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(widget.handAssetFor(move), fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _hand(widget.playerAMove, fromLeft: true, label: widget.playerALabel),
        Text(
          'VS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        _hand(widget.playerBMove, fromLeft: false, label: widget.playerBLabel),
      ],
    );
  }
}