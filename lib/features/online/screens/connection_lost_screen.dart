import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ConnectionLostScreen extends StatelessWidget {
  const ConnectionLostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text(
          'CONNECTION LOST',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}