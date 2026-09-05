import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

/// Auth state for the app (T84).
class AuthState {
  final bool isSignedIn;
  final String? username;
  final int? playerId;
  final String? rank;
  final int? rating;

  const AuthState({
    this.isSignedIn = false,
    this.username,
    this.playerId,
    this.rank,
    this.rating,
  });

  AuthState copyWith({
    bool? isSignedIn,
    String? username,
    int? playerId,
    String? rank,
    int? rating,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      username: username ?? this.username,
      playerId: playerId ?? this.playerId,
      rank: rank ?? this.rank,
      rating: rating ?? this.rating,
    );
  }
}

/// Manages authentication state using AuthClient (T80A).
class AuthController extends Notifier<AuthState> {
  late final AuthClient _client;

  @override
  AuthState build() {
    _client = AuthClient();
    _checkInitialAuth();
    return const AuthState();
  }

  /// On app start, check if a stored access token exists and fetch profile.
  void _checkInitialAuth() async {
    final hasToken = await _client.isAuthenticated;
    if (hasToken) {
      try {
        final response = await _client.get('/auth/profile');
        final data = response.data as Map<String, dynamic>;
        final player = data['player'] as Map<String, dynamic>?;
        state = AuthState(
          isSignedIn: true,
          username: player?['username'] as String?,
          playerId: player?['playerId'] as int?,
          rank: player?['rank'] as String?,
          rating: player?['rating'] as int?,
        );
      } catch (_) {
        state = const AuthState(isSignedIn: true);
      }
    }
  }

  /// Called after a successful login or register.
  void onLoginSuccess(Map<String, dynamic> result) {
    final player = result['player'] as Map<String, dynamic>?;
    state = AuthState(
      isSignedIn: true,
      username: player?['username'] as String?,
      playerId: player?['playerId'] as int?,
      rank: player?['rank'] as String?,
      rating: player?['rating'] as int?,
    );
  }

  /// Called to sign out.
  Future<void> signOut() async {
    await _client.logout();
    state = const AuthState();
  }

  /// Access the underlying AuthClient for API calls.
  AuthClient get client => _client;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
