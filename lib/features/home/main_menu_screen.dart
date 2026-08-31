import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/audio_service.dart';

class MainMenuScreen extends StatefulWidget {
  final bool isSignedIn;
  final VoidCallback onSinglePlayer;
  final VoidCallback onTwoPlayers;
  final VoidCallback onMultiplayer;
  final VoidCallback onLeaderboard;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const MainMenuScreen({
    super.key,
    required this.isSignedIn,
    required this.onSinglePlayer,
    required this.onTwoPlayers,
    required this.onMultiplayer,
    required this.onLeaderboard,
    required this.onSettings,
    required this.onProfile,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.playMusic();
  }

  Widget _menuButton(String label, VoidCallback onPressed, {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: primary
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.defaultAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'RPS ARENA',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              _menuButton('SINGLE PLAYER', widget.onSinglePlayer, primary: true),
              _menuButton('2 PLAYERS', widget.onTwoPlayers),
              _menuButton('MULTIPLAYER', widget.onMultiplayer),
              _menuButton('LEADERBOARD', widget.onLeaderboard),
              _menuButton('SETTINGS', widget.onSettings),
              if (widget.isSignedIn) _menuButton('PROFILE', widget.onProfile),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}