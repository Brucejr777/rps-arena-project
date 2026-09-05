import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hero_title.dart';
import '../../../core/widgets/input_card.dart';
import '../controllers/auth_controller.dart';

/// Register screen (T82).
///
/// Fields: username, password, confirm password.
/// Controls: submit button.
/// Feedback: message area (error / success).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() {
        _message = 'Please fill in all fields.';
        _isError = true;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _message = 'Passwords do not match.';
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
      final result = await auth.client.register(username: username, password: password);

      if (!mounted) return;

      // Update auth state so Main Menu enables online features
      auth.onLoginSuccess(result);

      final player = result['player'] as Map<String, dynamic>?;
      setState(() {
        _isLoading = false;
        _message = 'Account created! Welcome, ${player?['username'] ?? username}!';
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
      if (e.toString().contains('409') || e.toString().contains('already taken')) {
        errorMsg = 'Username already taken.';
      } else if (e.toString().contains('400')) {
        errorMsg = 'Please check your input (username 3–16 chars, password 8–64 chars).';
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
                        'REGISTER',
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

              // ── Hero title + subtitle ───────────────────────────
              const Center(child: HeroTitle(first: 'RPS', second: 'ARENA', fontSize: 26)),
              const SizedBox(height: 8),
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF03BBE8), Color(0xFFC631E0)],
                    stops: [0.2, 0.8],
                  ).createShader(bounds),
                  child: const Text(
                    'REGISTER',
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
                hint: '3–16 chars, letters, numbers, underscores',
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
                hint: '8–64 characters',
                obscure: true,
                onChanged: () {
                  if (_message != null) setState(() => _message = null);
                },
                onSubmitted: _submit,
              ),
              const SizedBox(height: 16),

              // ── Confirm Password card ───────────────────────────
              InputCard(
                icon: Icons.lock,
                label: 'CONFIRM PASSWORD',
                controller: _confirmPasswordController,
                hint: 'Re-enter your password',
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
                  label: 'REGISTER',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}