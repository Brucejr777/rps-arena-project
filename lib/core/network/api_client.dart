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
    String baseUrl = 'https://api.rpsarena.staging',
    TokenStorage? storage,
    Dio? dio,
  })  : _storage = storage ?? SecureTokenStorage(),
        dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              headers: {'Content-Type': 'application/json'},
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )) {
    this.dio.interceptors.add(_AuthInterceptor(this));
  }

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

  // ── Public API ───────────────────────────────────────────────────

  /// Register a new account. Returns player data on success.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
  }) async {
    final res = await dio.post('/auth/register', data: {
      'username': username,
      'password': password,
    });
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
    final res = await dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
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
        await dio.post('/auth/logout', data: {'refreshToken': rt});
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

  /// Make an authenticated GET request.
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  /// Make an authenticated POST request.
  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  /// Make an authenticated DELETE request.
  Future<Response> delete(String path) {
    return dio.delete(path);
  }
}

/// Dio interceptor that attaches the access token to every outgoing request
/// and transparently retries once after a 401 using a refreshed token.
class _AuthInterceptor extends Interceptor {
  final AuthClient _client;
  _AuthInterceptor(this._client);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _client.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If we got a 401 and haven't already retried, attempt a token refresh.
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['_retried'] != true) {
      try {
        await _client.refreshTokens();
        final newToken = await _client.accessToken;

        // Retry the original request with the fresh token.
        final opts = err.requestOptions;
        opts.extra['_retried'] = true;
        opts.headers['Authorization'] = 'Bearer $newToken';

        final res = await _client.dio.fetch(opts);
        handler.resolve(res);
        return;
      } catch (_) {
        // Refresh failed — let the original 401 propagate.
      }
    }
    handler.next(err);
  }
}
