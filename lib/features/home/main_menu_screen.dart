import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/theme/game_theme_controller.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/internet_service.dart';
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

  Widget _menuButton(String label, VoidCallback onPressed,
      {bool primary = false, bool enabled = true, String? disabledLabel, Color? accent}) {
    final color = accent ?? AppColors.defaultAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: enabled
            ? primary
                ? ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
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
                  )
            : OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            disabledLabel ?? 'ACCOUNT REQUIRED',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isSignedIn = auth.isSignedIn;
    final internetService = ref.watch(internetServiceProvider);
    final isConnected = internetService.isConnected;
    final accent = ref.watch(appAccentColorProvider);
    final gameTheme = ref.watch(gameThemeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ThemeBackground(
        theme: gameTheme,
        child: SafeArea(
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
              // ── Auth status + Login/Register buttons ────────────
              if (!isSignedIn) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onLogin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'LOGIN',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'REGISTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (isSignedIn) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome, ${auth.username ?? 'Player'}!',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(authControllerProvider.notifier).signOut();
                      },
                      child: const Text(
                        'SIGN OUT',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // ── Menu buttons ────────────────────────────────────
              _menuButton('SINGLE PLAYER', widget.onSinglePlayer, primary: true, accent: accent),
              _menuButton('2 PLAYERS', widget.onTwoPlayers, accent: accent),
              _menuButton('SETTINGS', widget.onSettings, accent: accent),

              // Disabled for guests or when offline
              _menuButton('MULTIPLAYER', widget.onMultiplayer, 
                enabled: isSignedIn && isConnected,
                disabledLabel: !isConnected ? 'INTERNET CONNECTION REQUIRED' : (isSignedIn ? null : 'ACCOUNT REQUIRED')),
              _menuButton('LEADERBOARD', widget.onLeaderboard, 
                enabled: isSignedIn && isConnected,
                disabledLabel: !isConnected ? 'INTERNET CONNECTION REQUIRED' : (isSignedIn ? null : 'ACCOUNT REQUIRED')),

              // Profile only visible when signed in
              if (isSignedIn)
                _menuButton('PROFILE', widget.onProfile),

              const Spacer(),
            ],
          ),
        ),
      ),
    ),
    );
  }
}