import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0F172A);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color defaultAccent = Color(0xFF2563EB);
  static const Color secondaryAccent = Color(0xFF7C3AED);

  static const Color blue = Color(0xFF2563EB);
  static const Color purple = Color(0xFF7C3AED);
  static const Color red = Color(0xFFDC2626);
  static const Color green = Color(0xFF16A34A);
  static const Color orange = Color(0xFFEA580C);

  // Subtle surface tone for cards, slightly lighter than background
  static const Color surface = Color(0xFF1E293B);

  // For soft glow/gradient accents on buttons and active states
 static LinearGradient accentGradient(Color accent) => LinearGradient(
      colors: [accent, accent.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
}