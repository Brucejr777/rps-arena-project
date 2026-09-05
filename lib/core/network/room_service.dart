import 'api_client.dart';

class RoomService {
  final AuthClient _auth;

  RoomService(this._auth);

  Future<Map<String, dynamic>> createRoom({
    required String formatType,
    int winsRequired = 0,
  }) async {
    final res = await _auth.post('/rooms/create', data: {
      'formatType': formatType,
      'winsRequired': winsRequired,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinRoom({required String roomCode}) async {
    final res = await _auth.post('/rooms/join', data: {
      'roomCode': roomCode,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startMatch({required String roomCode}) async {
    final res = await _auth.post('/rooms/start', data: {
      'roomCode': roomCode,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRoomStatus({required String roomCode}) async {
    final res = await _auth.get('/rooms/$roomCode');
    return res.data as Map<String, dynamic>;
  }
}
