import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RevealAnimation extends StatefulWidget {
  final String playerAMove;
  final String playerBMove;
  final String Function(String move) handAssetFor;

  const RevealAnimation({
    super.key,
    required this.playerAMove,
    required this.playerBMove,
    required this.handAssetFor,
  });

  @override
  State<RevealAnimation> createState() => _RevealAnimationState();
}

class _RevealAnimationState extends State<RevealAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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

  Widget _hand(String move, {required bool fromLeft}) {
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
      child: Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _hand(widget.playerAMove, fromLeft: true),
        Text(
          'VS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        _hand(widget.playerBMove, fromLeft: false),
      ],
    );
  }
}