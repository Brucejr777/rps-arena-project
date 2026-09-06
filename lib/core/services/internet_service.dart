import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Internet connectivity service (T108).
///
/// Monitors internet connectivity status and provides a stream of updates.
class InternetService {
  bool _isConnected = true;
  Timer? _checkTimer;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _controller.stream;

  InternetService() {
    // Start periodic connectivity checks
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  /// Check internet connectivity by attempting an HTTP request
  Future<void> _checkConnectivity() async {
    try {
      final response = await _dio.get('https://www.google.com');
      final connected = response.statusCode == 200;

      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(connected);
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _controller.add(false);
      }
    }
  }

  /// Manual refresh of connectivity status
  Future<bool> checkNow() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    _dio.close();
    _controller.close();
  }
}

/// Riverpod provider for InternetService
final internetServiceProvider = Provider<InternetService>((ref) {
  final service = InternetService();
  ref.onDispose(() => service.dispose());
  return service;
});
