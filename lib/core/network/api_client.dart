import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for token storage.
/// Allows swapping between secure storage (production) and in-memory (testing).
abstract class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production implementation backed by FlutterSecureStorage.
class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory implementation for testing.
class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
}

/// Flutter-side authentication client (T80A).
///
/// - Stores JWT access + refresh tokens securely.
/// - Attaches `Authorization: Bearer <token>` header to every request.
/// - Transparently refreshes expired access tokens via `POST /auth/refresh`.
/// - Provides `login`, `register`, `logout` helpers.
class AuthClient {
  final Dio dio;
  final TokenStorage _storage;

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  AuthClient({
    String baseUrl = 'https://rps-arena-project-3.onrender.com',
    TokenStorage? storage,
    Dio? dio,
  })  : _storage = storage ?? SecureTokenStorage(),
        dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              headers: {'Content-Type': 'application/json'},
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  // ── Token storage ────────────────────────────────────────────────

  Future<String?> get accessToken => _storage.read(accessTokenKey);
  Future<String?> get refreshToken => _storage.read(refreshTokenKey);

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(accessTokenKey, access);
    await _storage.write(refreshTokenKey, refresh);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(accessTokenKey);
    await _storage.delete(refreshTokenKey);
  }

  /// Attach the current access token to a request options object.
  Future<void> _attachToken(RequestOptions options) async {
    final token = await accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ── Public API ───────────────────────────────────────────────────

  /// Register a new account. Returns player data on success.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
  }) async {
    final options = RequestOptions(
      path: '/auth/register',
      method: 'POST',
      data: {'username': username, 'password': password},
    );
    await _attachToken(options);
    final res = await dio.fetch(options);
    final data = res.data as Map<String, dynamic>;
    await _saveTokens(
        data['accessToken'] as String, data['refreshToken'] as String);
    return data;
  }

  /// Login with credentials. Returns player data on success.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final options = RequestOptions(
      path: '/auth/login',
      method: 'POST',
      data: {'username': username, 'password': password},
    );
    await _attachToken(options);
    final res = await dio.fetch(options);
    final data = res.data as Map<String, dynamic>;
    await _saveTokens(
        data['accessToken'] as String, data['refreshToken'] as String);
    return data;
  }

  /// Logout: invalidate refresh token on server and clear local storage.
  Future<void> logout() async {
    final rt = await refreshToken;
    if (rt != null) {
      try {
        final options = RequestOptions(
          path: '/auth/logout',
          method: 'POST',
          data: {'refreshToken': rt},
        );
        await _attachToken(options);
        await dio.fetch(options);
      } catch (_) {
        // Best-effort — clear local tokens even if server call fails.
      }
    }
    await _clearTokens();
  }

  /// Exchange the current refresh token for a new token pair.
  Future<void> refreshTokens() async {
    final rt = await refreshToken;
    if (rt == null) throw Exception('No refresh token stored.');

    final res = await dio.post('/auth/refresh', data: {
      'refreshToken': rt,
    });
    final data = res.data as Map<String, dynamic>;
    await _saveTokens(
        data['accessToken'] as String, data['refreshToken'] as String);
  }

  /// Whether the user currently has a stored access token.
  Future<bool> get isAuthenticated async => (await accessToken) != null;

  /// Make an authenticated GET request, with automatic 401 retry.
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final options = RequestOptions(
      path: path,
      method: 'GET',
      queryParameters: queryParameters,
    );
    await _attachToken(options);

    try {
      return await dio.fetch(options);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Try token refresh and retry once
        try {
          await refreshTokens();
          final retryOptions = RequestOptions(
            path: path,
            method: 'GET',
            queryParameters: queryParameters,
          );
          await _attachToken(retryOptions);
          return await dio.fetch(retryOptions);
        } catch (_) {
          // Refresh failed — rethrow original error
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Make an authenticated POST request, with automatic 401 retry.
  Future<Response> post(String path, {dynamic data}) async {
    final options = RequestOptions(
      path: path,
      method: 'POST',
      data: data,
    );
    await _attachToken(options);

    try {
      return await dio.fetch(options);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        try {
          await refreshTokens();
          final retryOptions = RequestOptions(
            path: path,
            method: 'POST',
            data: data,
          );
          await _attachToken(retryOptions);
          return await dio.fetch(retryOptions);
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Make an authenticated DELETE request.
  Future<Response> delete(String path) async {
    final options = RequestOptions(
      path: path,
      method: 'DELETE',
    );
    await _attachToken(options);
    return await dio.fetch(options);
  }
}
