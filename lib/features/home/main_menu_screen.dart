import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/game_theme_controller.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/internet_service.dart';
import '../../core/widgets/hero_title.dart';
import '../../core/widgets/mode_card.dart';
import '../auth/controllers/auth_controller.dart';
import '../match/widgets/theme_background.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  final VoidCallback onSinglePlayer;
  final VoidCallback onTwoPlayers;
  final VoidCallback onMultiplayer;
  final VoidCallback onLeaderboard;
  final VoidCallback onSettings;
  final VoidCallback onProfile;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const MainMenuScreen({
    super.key,
    required this.onSinglePlayer,
    required this.onTwoPlayers,
    required this.onMultiplayer,
    required this.onLeaderboard,
    required this.onSettings,
    required this.onProfile,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.playMusic();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isSignedIn = auth.isSignedIn;
    final internetService = ref.watch(internetServiceProvider);
    final isConnected = internetService.isConnected;
    final gameTheme = ref.watch(gameThemeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ThemeBackground(
        theme: gameTheme,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top nav: profile chip + settings gear ─────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Profile chip (top-left)
                    GestureDetector(
                      onTap: isSignedIn ? widget.onProfile : widget.onLogin,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 1.5,
                                color: AppColors.blue,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.blue.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLAYER',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                isSignedIn ? (auth.username ?? 'Player') : 'Guest',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Settings gear (top-right)
                    GestureDetector(
                      onTap: widget.onSettings,
                      child: Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1.5,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Hero title ─────────────────────────────────
              const HeroTitle(first: 'RPS', second: 'ARENA'),
              const SizedBox(height: 16),
              const GameModeHeader(),
              // ── Guest auth row (only when not signed in) ──
              if (!isSignedIn) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: widget.onLogin,
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      '·',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    TextButton(
                      onPressed: widget.onRegister,
                      child: const Text(
                        'REGISTER',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // ── REMOVED: SIGN OUT button ──
                // Sign out is now accessible from the Profile screen.
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
              // ── Mode cards (wireframe order/copy/badges) ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView(
                    children: [
                      ModeCard(
                        iconAsset: 'assets/icons/icon_rocket.svg',
                        title: 'Multiplayer',
                        subtitle: 'Battle live players worldwide in Ranked Arena',
                        badgeLabel: isConnected ? 'ONLINE' : 'INTERNET REQUIRED',
                        badgeColor: AppColors.blue,
                        iconColor: AppColors.purple,
                        enabled: isSignedIn && isConnected,
                        onTap: widget.onMultiplayer,
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_bolt.svg',
                        title: 'Single Player',
                        subtitle: 'Sharpen your skills against advanced AI bots',
                        badgeLabel: 'PRACTICE',
                        badgeColor: AppColors.badgeGreen,
                        iconColor: AppColors.blue,
                        onTap: widget.onSinglePlayer,
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_gamepad.svg',
                        title: '2 Player',
                        subtitle: 'Local couch duel on a single screen',
                        badgeLabel: 'LOCAL',
                        badgeColor: AppColors.badgeGreen,
                        iconColor: AppColors.purple,
                        onTap: widget.onTwoPlayers,
                      ),
                      const SizedBox(height: 16),
                      ModeCard(
                        iconAsset: 'assets/icons/icon_trophy.svg',
                        title: 'Leaderboard',
                        subtitle: 'View top master competitors & local rankings',
                        badgeLabel: isConnected ? 'STATS' : 'INTERNET REQUIRED',
                        badgeColor: AppColors.badgeOrange,
                        iconColor: AppColors.orange,
                        enabled: isSignedIn && isConnected,
                        onTap: widget.onLeaderboard,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // ── Bottom Frame Indicator ─────────────────────
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}