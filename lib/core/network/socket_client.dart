import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Event types emitted by the server (T97A).
enum SocketEventType {
  opponentConnected,
  opponentFound,
  roundStart,
  roundResult,
  matchCompleted,
  opponentDisconnected,
  reconnectState,
  rematchRequested,
  rematchAccepted,
  rematchDeclined,
  matchCancelled,
}

/// Parsed socket event with type and data payload.
class SocketEvent {
  final SocketEventType type;
  final Map<String, dynamic> data;

  const SocketEvent({required this.type, required this.data});
}

/// Flutter WebSocket client for match events (T97A).
///
/// Connects to `wss://<host>/matches/{matchId}/events` and emits
/// typed [SocketEvent]s via a [Stream].
class MatchSocketClient {
  WebSocketChannel? _channel;
  final StreamController<SocketEvent> _controller =
      StreamController<SocketEvent>.broadcast();

  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  int _matchId = 0;
  int? _playerId;
  final String _baseUrl;

  MatchSocketClient({this._baseUrl = 'wss://rps-arena-project-3.onrender.com'});

  /// Stream of parsed socket events.
  Stream<SocketEvent> get events => _controller.stream;

  /// Whether the socket is currently connected.
  bool get isConnected => _isConnected;

  /// Connect to the match event stream.
  ///
  /// The server requires `playerId` as a query parameter and closes
  /// connections without it, so it must be provided.
  void connect(int matchId, {int? playerId}) {
    // Guard: disconnect existing connection before reconnecting.
    if (_channel != null) {
      _reconnectTimer?.cancel();
      _channel?.sink.close();
      _channel = null;
      _isConnected = false;
    }
    _matchId = matchId;
    if (playerId != null) _playerId = playerId;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    final url = _playerId != null
        ? '$_baseUrl/matches/$_matchId/events?playerId=$_playerId'
        : '$_baseUrl/matches/$_matchId/events';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Mark connected as soon as the handshake succeeds.
      _channel!.ready.then((_) {
        _isConnected = true;
        _reconnectAttempts = 0;
      }).catchError((_) {
        // Connection failed — reconnect handler will take over.
      });

      _channel!.stream.listen(
        (data) {
          _isConnected = true;
          _handleMessage(data);
        },
        onDone: () {
          _isConnected = false;
          _attemptReconnect();
        },
        onError: (error) {
          _isConnected = false;
          _controller.addError(error);
        },
      );
    } catch (e) {
      _isConnected = false;
      _attemptReconnect();
    }
  }

  void _handleMessage(dynamic rawData) {
    try {
      final message = jsonDecode(rawData as String) as Map<String, dynamic>;
      final typeStr = message['type'] as String?;

      if (typeStr == null) return;

      final type = _parseEventType(typeStr);
      if (type == null) return;

      _controller.add(SocketEvent(type: type, data: message));
    } catch (_) {
      // Malformed message — ignore
    }
  }

  SocketEventType? _parseEventType(String type) {
    switch (type) {
      case 'opponent_connected':
        return SocketEventType.opponentConnected;
      case 'opponent_found':
        return SocketEventType.opponentFound;
      case 'round_start':
        return SocketEventType.roundStart;
      case 'round_result':
        return SocketEventType.roundResult;
      case 'match_completed':
        return SocketEventType.matchCompleted;
      case 'opponent_disconnected':
        return SocketEventType.opponentDisconnected;
      case 'reconnect_state':
        return SocketEventType.reconnectState;
      case 'rematch_requested':
        return SocketEventType.rematchRequested;
      case 'rematch_accepted':
        return SocketEventType.rematchAccepted;
      case 'rematch_declined':
        return SocketEventType.rematchDeclined;
      case 'match_cancelled':
        return SocketEventType.matchCancelled;
      default:
        return null;
    }
  }

  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    // Exponential backoff: 1s, 2s, 4s, 8s … capped at 30s.
    final delaySeconds = [
      1,
      2,
      4,
      8,
      15,
      30,
      30,
      30,
      30,
      30,
    ][_reconnectAttempts.clamp(0, 9)];
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isConnected) {
        _doConnect();
      }
    });
  }

  /// Send a message to the server.
  void send(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Disconnect from the server.
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Dispose all resources.
  void dispose() {
    disconnect();
    _controller.close();
  }
}
