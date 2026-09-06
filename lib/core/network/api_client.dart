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

  /// Mutex for token refresh — prevents concurrent refresh calls.
  Future<void>? _refreshMutex;

  /// Build Options with the current access token attached.
  Future<Options> _authOptions() async {
    final token = await accessToken;
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  // ── Public API ───────────────────────────────────────────────────

  /// Register a new account. Returns player data on success.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
  }) async {
    final opts = await _authOptions();
    final res = await dio.post('/auth/register',
        data: {'username': username, 'password': password}, options: opts);
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
    final opts = await _authOptions();
    final res = await dio.post('/auth/login',
        data: {'username': username, 'password': password}, options: opts);
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
        final opts = await _authOptions();
        await dio.post('/auth/logout',
            data: {'refreshToken': rt}, options: opts);
      } catch (_) {
        // Best-effort — clear local tokens even if server call fails.
      }
    }
    await _clearTokens();
  }

  /// Exchange the current refresh token for a new token pair.
  /// Uses a mutex so concurrent 401s share a single refresh call.
  Future<void> refreshTokens() async {
    // If a refresh is already in progress, wait for it.
    if (_refreshMutex != null) {
      await _refreshMutex;
      return;
    }

    _refreshMutex = _doRefresh();
    try {
      await _refreshMutex;
    } finally {
      _refreshMutex = null;
    }
  }

  Future<void> _doRefresh() async {
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
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final opts = await _authOptions();
    try {
      return await dio.get(path, queryParameters: queryParameters, options: opts);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        try {
          await refreshTokens();
          final retryOpts = await _authOptions();
          return await dio.get(path,
              queryParameters: queryParameters, options: retryOpts);
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Make an authenticated POST request, with automatic 401 retry.
  Future<Response> post(String path, {dynamic data}) async {
    final opts = await _authOptions();
    try {
      return await dio.post(path, data: data, options: opts);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        try {
          await refreshTokens();
          final retryOpts = await _authOptions();
          return await dio.post(path, data: data, options: retryOpts);
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Make an authenticated DELETE request, with automatic 401 retry.
  Future<Response> delete(String path) async {
    final opts = await _authOptions();
    try {
      return await dio.delete(path, options: opts);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        try {
          await refreshTokens();
          final retryOpts = await _authOptions();
          return await dio.delete(path, options: retryOpts);
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }
}
