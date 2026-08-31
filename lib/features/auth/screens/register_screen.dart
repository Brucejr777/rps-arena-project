import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';

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
      final client = AuthClient();
      final result =
          await client.register(username: username, password: password);

      if (!mounted) return;

      final player = result['player'] as Map<String, dynamic>?;
      setState(() {
        _isLoading = false;
        _message = 'Account created! Welcome, ${player?['username'] ?? username}!';
        _isError = false;
      });

      // TODO: navigate to main menu with authenticated state (T84)
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'REGISTER',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Username field ──────────────────────────────────
              const Text('Username',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: AppColors.primaryText),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('3–16 characters, letters, numbers, underscores'),
                onChanged: (_) {
                  if (_message != null) setState(() => _message = null);
                },
              ),
              const SizedBox(height: 20),

              // ── Password field ──────────────────────────────────
              const Text('Password',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.primaryText),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('8–64 characters'),
                onChanged: (_) {
                  if (_message != null) setState(() => _message = null);
                },
              ),
              const SizedBox(height: 20),

              // ── Confirm Password field ──────────────────────────
              const Text('Confirm Password',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.primaryText),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: _fieldDecoration('Re-enter your password'),
                onChanged: (_) {
                  if (_message != null) setState(() => _message = null);
                },
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

              // ── Submit button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'REGISTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
