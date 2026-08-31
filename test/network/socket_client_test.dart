import 'package:flutter_test/flutter_test.dart';
import 'package:rps_arena/core/network/socket_client.dart';

void main() {
  group('SocketEventType', () {
    test('all 6 event types are defined', () {
      expect(SocketEventType.values.length, 6);
    });
  });

  group('MatchSocketClient', () {
    late MatchSocketClient client;

    setUp(() {
      client = MatchSocketClient();
    });

    tearDown(() {
      client.dispose();
    });

    test('starts disconnected', () {
      expect(client.isConnected, isFalse);
    });

    test('events stream is broadcast', () {
      // Multiple listeners should not throw
      expect(() {
        client.events.listen((_) {});
        client.events.listen((_) {});
      }, returnsNormally);
    });

    test('disconnect sets isConnected to false', () {
      client.disconnect();
      expect(client.isConnected, isFalse);
    });
  });

  group('SocketEvent', () {
    test('stores type and data', () {
      const event = SocketEvent(
        type: SocketEventType.roundResult,
        data: {'result': 'player_a_wins', 'roundNumber': 1},
      );

      expect(event.type, SocketEventType.roundResult);
      expect(event.data['result'], 'player_a_wins');
      expect(event.data['roundNumber'], 1);
    });

    test('all 6 event types can be constructed', () {
      for (final type in SocketEventType.values) {
        final event = SocketEvent(type: type, data: {});
        expect(event.type, type);
      }
    });
  });
}
