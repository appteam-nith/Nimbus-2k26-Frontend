import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room_model.dart';

/// HTTP client for the Nimbus Mafia backend.
/// JWT is read from SharedPreferences (key: 'jwt_token').
/// Base URL is read from env or falls back to the Render deployment.
class GameApi {
  GameApi._();
  static final GameApi instance = GameApi._();

  static const String _baseUrl =
      'https://nimbus-2k26-backend-olhw.onrender.com';

  // ─── TOKEN ──────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // AuthProvider saves the token with key 'auth_token'
    return prefs.getString('auth_token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─── ROOM STATE (Reconnect entry point) ─────────────────────────────────────

  /// GET /api/game/rooms/:code
  /// Returns [RoomModel] with [myRole] and [timeRemaining] populated.
  /// Throws [GameApiException] on failure.
  Future<RoomModel> getRoomState(String roomCode) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final uri = Uri.parse('$_baseUrl/api/game/rooms/$roomCode');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RoomModel.fromJson(json);
    } else if (response.statusCode == 404) {
      throw const GameApiException('Room not found', 404);
    } else {
      final body = _tryDecodeError(response.body);
      throw GameApiException(body, response.statusCode);
    }
  }

  // ─── LIST OPEN ROOMS ─────────────────────────────────────────────────────────

  /// GET /api/game/rooms — returns all LOBBY rooms for the browse screen.
  Future<List<Map<String, dynamic>>> listRooms() async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final uri = Uri.parse('$_baseUrl/api/game/rooms');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['rooms'] as List<dynamic>? ?? [])
          .map((r) => r as Map<String, dynamic>)
          .toList();
    } else {
      throw GameApiException(
        _tryDecodeError(response.body),
        response.statusCode,
      );
    }
  }

  // ─── GAME ACTIONS (Dev 3) ───────────────────────────────────────────────────

  /// POST /api/game/vote
  /// Sends a game action (Vote, Kill, Save, etc.) to the backend.
  Future<void> postAction(
    String roomCode,
    String targetId,
    String actionType,
  ) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final uri = Uri.parse('$_baseUrl/api/game/vote');
    final response = await http
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({
            'room_code': roomCode,
            'target_id': targetId,
            'vote_type': actionType,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw GameApiException(
        _tryDecodeError(response.body),
        response.statusCode,
      );
    }
  }

  // ─── ROOM APIs (Dev 2) ───────────────────────────────────────────────────────

  /// POST /api/game/rooms
  /// [roomSize] must be "FIVE", "EIGHT", or "TWELVE".
  /// Returns the room code.
  Future<String> createRoom(String roomSize) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final uri = Uri.parse('$_baseUrl/api/game/rooms');
    final response = await http
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({'room_size': roomSize}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['roomCode'] as String;
    }
    throw GameApiException(_tryDecodeError(response.body), response.statusCode);
  }

  /// POST /api/game/rooms/join
  /// [roomCode] is the 6-character room code.
  Future<void> joinRoom(String roomCode) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final uri = Uri.parse('$_baseUrl/api/game/rooms/join');
    final response = await http
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({'room_code': roomCode}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw GameApiException(
        _tryDecodeError(response.body),
        response.statusCode,
      );
    }
  }

  /// POST /api/game/rooms/leave
  /// [roomCode] is the 6-character room code.
  Future<void> leaveRoom(String roomCode) async {
    final token = await _getToken();
    if (token == null) return; // Ignore if not authenticated

    final uri = Uri.parse('$_baseUrl/api/game/rooms/leave');
    try {
      await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({'room_code': roomCode}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Best effort when leaving
    }
  }

  /// POST /api/game/start — host only.
  Future<void> startGame(String roomCode, {bool devMode = false}) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final uri = Uri.parse('$_baseUrl/api/game/start');
    final response = await http
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({'room_code': roomCode, 'dev_mode': devMode}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw GameApiException(
        _tryDecodeError(response.body),
        response.statusCode,
      );
    }
  }

  // ─── GAME ACTIONS (Dev 4) ───────────────────────────────────────────────────

  /// POST /api/vote
  /// Optional arrays for Hitman or other complex actions.
  Future<String?> submitVote(
    String roomCode,
    String voteType, {
    List<String>? targets,
    List<String>? roles,
  }) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final payload = <String, dynamic>{
      'room_code': roomCode,
      'vote_type': voteType,
    };

    if (targets != null && targets.isNotEmpty) {
      payload['targets'] = targets;
    }

    if (roles != null && roles.isNotEmpty) {
      payload['roles'] = roles;
    }

    final uri = Uri.parse('$_baseUrl/api/game/vote');
    final response = await http
        .post(uri, headers: _headers(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw GameApiException(
        _tryDecodeError(response.body),
        response.statusCode,
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // The backend may return 'investigation_result' for Cop/Reporter
      return json['investigation_result'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── CHAT ───────────────────────────────────────────────────────────────────

  /// POST /api/game/chat
  /// [channel] is one of: null (global), 'mafia', 'doc'
  Future<void> sendChat(
    String roomCode,
    String message, {
    String? channel,
  }) async {
    final token = await _getToken();
    if (token == null) throw const GameApiException('Not authenticated', 401);

    final payload = <String, dynamic>{
      'room_code': roomCode,
      'message': message,
      // ignore: use_null_aware_elements
      if (channel != null) 'channel': channel,
    };

    final uri = Uri.parse('$_baseUrl/api/game/chat');
    final response = await http
        .post(uri, headers: _headers(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw GameApiException(
        _tryDecodeError(response.body),
        response.statusCode,
      );
    }
  }

  // ─── ACTIVE ROOM PERSISTENCE ────────────────────────────────────────────────

  /// Persists the room code so reconnect works on app relaunch.
  Future<void> saveActiveRoom(String roomCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_room_code', roomCode);
  }

  /// Returns the persisted room code, or null if none.
  Future<String?> getActiveRoomCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_room_code');
  }

  /// Clears the persisted room code (call on game-ended or home navigation).
  Future<void> clearActiveRoom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_room_code');
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  String _tryDecodeError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error'] as String? ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }
}

// ─── EXCEPTION ────────────────────────────────────────────────────────────────

class GameApiException implements Exception {
  final String message;
  final int statusCode;

  const GameApiException(this.message, this.statusCode);

  @override
  String toString() => 'GameApiException($statusCode): $message';
}
