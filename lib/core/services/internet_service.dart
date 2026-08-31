import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Internet connectivity service (T108).
///
/// Monitors internet connectivity status and provides a stream of updates.
class InternetService {
  bool _isConnected = true;
  Timer? _checkTimer;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

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

  /// Check internet connectivity by attempting DNS lookup
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

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
    _controller.close();
  }
}

/// Riverpod provider for InternetService
final internetServiceProvider = Provider<InternetService>((ref) {
  final service = InternetService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Riverpod provider for current connectivity status
final isConnectedProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(internetServiceProvider);
  return service.onConnectivityChanged;
});
