import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:rps_arena/core/network/api_client.dart';

/// Helper to create a simple MockAdapter from a handler function.
HttpClientAdapter _mockAdapter(
    ResponseBody Function(RequestOptions) handler) {
  return _SimpleMockAdapter(handler);
}

class _SimpleMockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) _handler;
  _SimpleMockAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Creates a ResponseBody with JSON content type so Dio's transformer
/// decodes the string into a Map.
ResponseBody _jsonBody(String json, [int statusCode = 200]) {
  return ResponseBody.fromString(
    json,
    statusCode,
    headers: {'content-type': ['application/json']},
  );
}

void main() {
  late InMemoryTokenStorage storage;
  late Dio dio;
  late AuthClient client;

  setUp(() {
    storage = InMemoryTokenStorage();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    client = AuthClient(
      baseUrl: 'http://localhost',
      storage: storage,
      dio: dio,
    );
  });

  // ── Token storage ──────────────────────────────────────────────

  group('Token storage', () {
    test('starts with no tokens', () async {
      expect(await client.accessToken, isNull);
      expect(await client.refreshToken, isNull);
      expect(await client.isAuthenticated, isFalse);
    });

    test('saveTokens stores both tokens', () async {
      await storage.write(AuthClient.accessTokenKey, 'at_123');
      await storage.write(AuthClient.refreshTokenKey, 'rt_456');

      expect(await client.accessToken, 'at_123');
      expect(await client.refreshToken, 'rt_456');
      expect(await client.isAuthenticated, isTrue);
    });

    test('clearTokens removes both tokens', () async {
      await storage.write(AuthClient.accessTokenKey, 'at_123');
      await storage.write(AuthClient.refreshTokenKey, 'rt_456');
      await storage.delete(AuthClient.accessTokenKey);
      await storage.delete(AuthClient.refreshTokenKey);

      expect(await client.accessToken, isNull);
      expect(await client.refreshToken, isNull);
      expect(await client.isAuthenticated, isFalse);
    });
  });

  // ── Login ─────────────────────────────────────────────────────

  group('login', () {
    test('stores tokens on successful login', () async {
      dio.httpClientAdapter = _mockAdapter((options) {
        expect(options.path, '/auth/login');
        expect(options.data['username'], 'player1');
        expect(options.data['password'], 'secret123');
        return _jsonBody(
          '{"player":{"playerId":1,"username":"player1","rating":1000,"rank":"Bronze"},"accessToken":"access_tok","refreshToken":"refresh_tok"}',
        );
      });

      final result = await client.login(username: 'player1', password: 'secret123');

      expect(result['player']['username'], 'player1');
      expect(await client.accessToken, 'access_tok');
      expect(await client.refreshToken, 'refresh_tok');
    });
  });

  // ── Register ──────────────────────────────────────────────────

  group('register', () {
    test('stores tokens on successful register', () async {
      dio.httpClientAdapter = _mockAdapter((options) {
        expect(options.path, '/auth/register');
        expect(options.data['username'], 'newplayer');
        expect(options.data['password'], 'strongpass');
        return _jsonBody(
          '{"player":{"playerId":2,"username":"newplayer","rating":1000,"rank":"Bronze"},"accessToken":"new_at","refreshToken":"new_rt"}',
        );
      });

      final result =
          await client.register(username: 'newplayer', password: 'strongpass');

      expect(result['player']['username'], 'newplayer');
      expect(await client.accessToken, 'new_at');
      expect(await client.refreshToken, 'new_rt');
    });
  });

  // ── Logout ────────────────────────────────────────────────────

  group('logout', () {
    test('clears tokens and sends logout request', () async {
      await storage.write(AuthClient.accessTokenKey, 'at_123');
      await storage.write(AuthClient.refreshTokenKey, 'rt_456');

      dio.httpClientAdapter = _mockAdapter((options) {
        expect(options.path, '/auth/logout');
        expect(options.data['refreshToken'], 'rt_456');
        return _jsonBody('{"message":"Logged out."}');
      });

      await client.logout();

      expect(await client.accessToken, isNull);
      expect(await client.refreshToken, isNull);
      expect(await client.isAuthenticated, isFalse);
    });

    test('clears tokens even if server call fails', () async {
      await storage.write(AuthClient.accessTokenKey, 'at_123');
      await storage.write(AuthClient.refreshTokenKey, 'rt_456');

      dio.httpClientAdapter = _mockAdapter((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      await client.logout();

      expect(await client.accessToken, isNull);
      expect(await client.refreshToken, isNull);
    });
  });

  // ── Authorization header ──────────────────────────────────────

  group('Authorization header', () {
    test('attaches Bearer token to requests', () async {
      await storage.write(AuthClient.accessTokenKey, 'my_token');

      dio.httpClientAdapter = _mockAdapter((options) {
        expect(options.headers['Authorization'], 'Bearer my_token');
        return _jsonBody('{}');
      });

      await client.get('/some/path');
    });

    test('sends no Authorization header when unauthenticated', () async {
      dio.httpClientAdapter = _mockAdapter((options) {
        expect(options.headers.containsKey('Authorization'), isFalse);
        return _jsonBody('{}');
      });

      await client.get('/some/path');
    });
  });

  // ── Auto-refresh on 401 ───────────────────────────────────────

  group('401 auto-refresh', () {
    test('retries with new token after 401 and successful refresh', () async {
      await storage.write(AuthClient.accessTokenKey, 'expired_token');
      await storage.write(AuthClient.refreshTokenKey, 'refresh_tok');

      var requestCount = 0;
      dio.httpClientAdapter = _mockAdapter((options) {
        requestCount++;

        if (options.path == '/protected' && requestCount == 1) {
          // First request: return 401
          return _jsonBody('{"error":"Unauthorized"}', 401);
        }

        if (options.path == '/auth/refresh') {
          // Refresh call: return new tokens
          return _jsonBody(
            '{"accessToken":"fresh_at","refreshToken":"fresh_rt"}',
          );
        }

        if (options.path == '/protected' && requestCount == 3) {
          // Retry: should have the new token
          expect(options.headers['Authorization'], 'Bearer fresh_at');
          return _jsonBody('{"data":"success"}');
        }

        return _jsonBody('{}', 500);
      });

      final res = await client.get('/protected');
      expect(res.statusCode, 200);
      expect(requestCount, 3); // original + refresh + retry
    });
  });
}
