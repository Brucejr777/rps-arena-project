import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/animation_speed_controller.dart';

class RevealAnimation extends ConsumerStatefulWidget {
  final String playerAMove;
  final String playerBMove;
  final String Function(String move) handAssetFor;
  final String playerALabel;
  final String playerBLabel;
  final bool playerAAuto;
  final bool playerBAuto;

  /// NEW: optional round result so the widget can highlight the winner.
  /// Accepts 'player_a_wins', 'player_b_wins', 'draw', or null.
  final String? roundResult;

  const RevealAnimation({
    super.key,
    required this.playerAMove,
    required this.playerBMove,
    required this.handAssetFor,
    this.playerALabel = 'PLAYER 1',
    this.playerBLabel = 'PLAYER 2',
    this.playerAAuto = false,
    this.playerBAuto = false,
    this.roundResult,
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

  // ── helpers ──────────────────────────────────────────────────
  bool get _aWon => widget.roundResult == 'player_a_wins';
  bool get _bWon => widget.roundResult == 'player_b_wins';
  bool get _isDraw => widget.roundResult == 'draw';

  Color _borderColor(bool isA) {
    if (widget.roundResult == null) return Colors.white12;
    if (_isDraw) return AppColors.orange;
    if (isA && _aWon) return AppColors.green;
    if (!isA && _bWon) return AppColors.green;
    return AppColors.red.withValues(alpha: 0.6);
  }

  String get _resultText {
    if (widget.roundResult == null) return '';
    if (_isDraw) return 'DRAW';
    if (_aWon) return '${widget.playerALabel} WINS THE ROUND';
    return '${widget.playerBLabel} WINS THE ROUND';
  }

  Color get _resultColor {
    if (_isDraw) return AppColors.orange;
    return AppColors.green;
  }

  Widget _hand(
    String move, {
    required bool fromLeft,
    required String label,
    required bool isAuto,
    required bool isA,
  }) {
    final border = _borderColor(isA);
    final isWinner =
        (isA && _aWon) || (!isA && _bWon);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            fromLeft ? _slideAnimation.value : -_slideAnimation.value;
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
              border: Border.all(
                width: isWinner ? 2.5 : 1.5,
                color: border,
              ),
              boxShadow: [
                if (isWinner)
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.5),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child:
                Image.asset(widget.handAssetFor(move), fit: BoxFit.contain),
          ),
          if (isAuto)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AUTO',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _hand(widget.playerAMove,
                fromLeft: true,
                label: widget.playerALabel,
                isAuto: widget.playerAAuto,
                isA: true),
            Text(
              'VS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            _hand(widget.playerBMove,
                fromLeft: false,
                label: widget.playerBLabel,
                isAuto: widget.playerBAuto,
                isA: false),
          ],
        ),
        // ── NEW: round result banner ──────────────────────────
        if (widget.roundResult != null) ...[
          const SizedBox(height: 16),
          Text(
            _resultText,
            style: TextStyle(
              color: _resultColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: _resultColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}