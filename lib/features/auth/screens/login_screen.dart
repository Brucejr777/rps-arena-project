import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hero_title.dart';
import '../../../core/widgets/input_card.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';

/// Login screen (T81).
///
/// Fields: username, password.
/// Controls: submit button.
/// Feedback: message area (error / success).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = true; // red for errors, green for success

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Please enter both username and password.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final auth = ref.read(authControllerProvider.notifier);
      final result = await auth.client.login(username: username, password: password);

      if (!mounted) return;

      // Update auth state so Main Menu enables online features
      auth.onLoginSuccess(result);

      final player = result['player'] as Map<String, dynamic>?;
      setState(() {
        _isLoading = false;
        _message = 'Welcome back, ${player?['username'] ?? username}!';
        _isError = false;
      });

      // Navigate back to main menu after brief delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;

      String errorMsg;
      if (e.toString().contains('401') || e.toString().contains('Invalid')) {
        errorMsg = 'Invalid username or password.';
      } else if (e.toString().contains('400')) {
        errorMsg = 'Please check your input.';
      } else {
        errorMsg = 'Connection failed. Please try again.';
      }

      setState(() {
        _isLoading = false;
        _message = errorMsg;
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'LOGIN',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Hero title + LOGIN subtitle ─────────────────────
              const Center(child: HeroTitle(first: 'RPS', second: 'ARENA', fontSize: 26)),
              const SizedBox(height: 8),
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF03BBE8), Color(0xFFC631E0)],
                    stops: [0.2, 0.8],
                  ).createShader(bounds),
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Username card ───────────────────────────────────
              InputCard(
                icon: Icons.person,
                label: 'USERNAME',
                controller: _usernameController,
                hint: 'Enter your username',
                obscure: false,
                onChanged: () {
                  if (_message != null) setState(() => _message = null);
                },
                onSubmitted: _submit,
              ),
              const SizedBox(height: 16),

              // ── Password card ───────────────────────────────────
              InputCard(
                icon: Icons.lock,
                label: 'PASSWORD',
                controller: _passwordController,
                hint: 'Enter your password',
                obscure: true,
                onChanged: () {
                  if (_message != null) setState(() => _message = null);
                },
                onSubmitted: _submit,
              ),

              // ── Message area ────────────────────────────────────
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _isError ? AppColors.red : AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              // ── Submit button (gradient-border pill) ────────────
              SizedBox(
                width: double.infinity,
                child: GradientPillButton(
                  label: 'LOGIN',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 16),

              // ── Footer ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "DON'T HAVE AN ACCOUNT?",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}