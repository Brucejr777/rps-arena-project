import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Input field card matching the wireframe auth screens (24/25):
/// icon on the left, uppercase label above a rounded input box.
///
/// When [obscure] is true a visibility-toggle (eye) icon is shown so the
/// user can peek at the password.
class InputCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  const InputCard({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<InputCard> {
  /// Local visibility state – starts hidden when [widget.obscure] is true.
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  void didUpdateWidget(covariant InputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent changes the obscure flag, sync local state.
    if (oldWidget.obscure != widget.obscure) {
      _obscured = widget.obscure;
    }
  }

  void _toggleVisibility() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF03BBE8), Color(0xFFC631E0)],
          stops: [0.2, 0.8],
        ),
        borderRadius: BorderRadius.circular(19.5),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF475569),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: widget.controller,
                    // ── FIX: driven by local _obscured state ──
                    obscureText: _obscured,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                    // Keep keyboard action tied to the *original* intent,
                    // not the current visibility toggle.
                    textInputAction: widget.obscure
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onSubmitted: (_) => widget.onSubmitted(),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.5),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.5),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.blue,
                        ),
                      ),
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      // ── FIX: peek / hide toggle for password fields ──
                      suffixIcon: widget.obscure
                          ? IconButton(
                              onPressed: _toggleVisibility,
                              icon: Icon(
                                _obscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white38,
                                size: 20,
                              ),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 24,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient-border pill button matching the wireframe auth submit buttons.
class GradientPillButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GradientPillButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF03BBE8), Color(0xFFC631E0)],
          stops: [0.2, 0.8],
        ),
        borderRadius: BorderRadius.circular(19.5),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF475569),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            disabledBackgroundColor: Colors.transparent,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}