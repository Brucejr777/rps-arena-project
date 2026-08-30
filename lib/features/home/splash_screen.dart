import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Offline modes load without internet — no network dependency here,
    // so this always proceeds after the fixed duration regardless of
    // connectivity.
    Future.delayed(const Duration(seconds: 2), widget.onFinished);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'RPS ARENA',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: [
                  Shadow(color: AppColors.defaultAccent, blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.defaultAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}