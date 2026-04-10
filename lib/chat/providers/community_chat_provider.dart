import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../mafia/services/pusher_service.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

class CommunityChatProvider extends ChangeNotifier {
  static const String publicRoomName = 'Public Chat';
  static const String _baseUrl = 'https://nimbus-2k26-backend-olhw.onrender.com';

  final Map<String, CommunityChatRoom> _rooms = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<CommunityChatRoom> get rooms {
    final all = _rooms.values.toList();
    all.sort((a, b) {
      if (a.isPublic && !b.isPublic) return -1;
      if (!a.isPublic && b.isPublic) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return all;
  }

  List<CommunityChatRoom> get customRooms =>
      rooms.where((room) => !room.isPublic).toList();

  CommunityChatRoom? roomByName(String roomName) {
    return _rooms[roomName.trim()];
  }
  
  List<String> participantsInRoom(String roomName) {
    // Member tracking was moved to stateless backend messages.
    return const [];
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Main initialization
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await fetchRooms();
      _setupGlobalPusher();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[CommunityChat] Failed to initialize: $e');
    }
  }

  /// Listen to global events for room creation/updates
  void _setupGlobalPusher() {
    // Note: To receive pusher events, the backend triggers on 'community-global'.
    // Pusher channels flutter needs us to subscribe to it explicitly if not using a unified channel.
    PusherService.instance.subscribeToGlobalCommunityChat(_onGlobalPusherEvent);
  }
  
  void _onGlobalPusherEvent(dynamic event) {
    // Expected to be integrated in PusherService
    try {
      if (event != null && event['event'] != null) {
        final eventName = event['event'];
        final data = jsonDecode(event['data']);
        if (eventName == 'room-created' || eventName == 'room-updated') {
          final room = CommunityChatRoom.fromJson(data);
          _rooms[room.name] = room;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Load all rooms from the backend
  Future<void> fetchRooms() async {
    final token = await _getToken() ?? '';
    final url = Uri.parse('$_baseUrl/api/community-chat/rooms');
    final res = await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      _rooms.clear();
      for (final r in (json['rooms'] as List)) {
        final room = CommunityChatRoom.fromJson(r);
        _rooms[room.name] = room;
      }
      notifyListeners();
    }
  }

  Future<String?> createRoom({
    required String name,
    required String createdById,
    required String createdByName,
    required bool lockRoom,
    String? password,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'Room name cannot be empty.';

    final token = await _getToken() ?? '';
    final url = Uri.parse('$_baseUrl/api/community-chat/rooms');
    
    try {
      final res = await http.post(
        url, 
        headers: _headers(token),
        body: jsonEncode({
          'name': trimmedName,
          'createdById': createdById,
          'createdByName': createdByName,
          'isLocked': lockRoom,
          'password': lockRoom ? password : null
        })
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body)['room'];
        final room = CommunityChatRoom.fromJson(data);
        _rooms[room.name] = room;
        notifyListeners();
        return null;
      } else {
        return jsonDecode(res.body)['error'] ?? 'Failed to create room';
      }
    } catch (e) {
      return 'Network error creating room';
    }
  }

  Future<bool> verifyRoomPassword({
    required String roomName,
    required String password,
  }) async {
    final token = await _getToken() ?? '';
    final url = Uri.parse('$_baseUrl/api/community-chat/rooms/$roomName/verify');
    
    try {
      final res = await http.post(
        url, 
        headers: _headers(token),
        body: jsonEncode({'password': password})
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body)['verified'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> updateRoomLock({
    required String roomName,
    required String requesterUserId,
    required bool shouldLock,
    String? password,
  }) async {
    final token = await _getToken() ?? '';
    final url = Uri.parse('$_baseUrl/api/community-chat/rooms/$roomName/lock');
    
    try {
      final res = await http.post(
        url, 
        headers: _headers(token),
        body: jsonEncode({
          'requesterUserId': requesterUserId,
          'shouldLock': shouldLock,
          'password': password
        })
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['room'];
        final room = CommunityChatRoom.fromJson(data);
        // Retain existing messages client side
        room.messages.addAll(_rooms[roomName]?.messages ?? []);
        _rooms[room.name] = room;
        notifyListeners();
        return null;
      } else {
        return jsonDecode(res.body)['error'] ?? 'Failed to update lock';
      }
    } catch (e) {
      return 'Network error updating lock';
    }
  }

  Future<String?> sendMessage({
    required String roomName,
    required String senderNickname,
    required String text,
  }) async {
    final token = await _getToken() ?? '';
    final url = Uri.parse('$_baseUrl/api/community-chat/rooms/$roomName/messages');
    
    try {
      final res = await http.post(
        url, 
        headers: _headers(token),
        body: jsonEncode({
          'senderNickname': senderNickname,
          'text': text
        })
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return null; // Successfully sent. Rely on Pusher to render it.
      } else {
        return jsonDecode(res.body)['error'] ?? 'Failed to send msg';
      }
    } catch (e) {
      return 'Network error sending message';
    }
  }

  Future<String?> joinRoom({
    required String roomName,
    required String userId,
    required String nickname,
  }) async {
    final token = await _getToken() ?? '';
    
    // First, fetch existing messages
    try {
      final msgUrl = Uri.parse('$_baseUrl/api/community-chat/rooms/$roomName/messages');
      final msgRes = await http.get(msgUrl, headers: _headers(token)).timeout(const Duration(seconds: 10));
      
      if (msgRes.statusCode == 200) {
        final data = jsonDecode(msgRes.body);
        final roomData = data['room'];
        if (roomData != null) {
           final room = CommunityChatRoom.fromJson(roomData);
           room.messages.clear();
           for (final m in data['messages']) {
             room.messages.add(CommunityChatMessage.fromJson(m));
           }
           _rooms[roomName] = room;
           
           // Subscribe to pusher channel for this specific room
           PusherService.instance.subscribeToCommunityRoom(room.id, _onRoomPusherEvent);
        }
      }
      
      // Notify backend of join
      final url = Uri.parse('$_baseUrl/api/community-chat/rooms/$roomName/join');
      await http.post(
        url, 
        headers: _headers(token),
        body: jsonEncode({'userId': userId, 'nickname': nickname})
      ).timeout(const Duration(seconds: 5));

      notifyListeners();
      return null;
    } catch (e) {
      return 'Network error joining room';
    }
  }

  Future<void> leaveRoom({
    required String roomName,
    required String userId,
    String? nickname,
  }) async {
    final token = await _getToken() ?? '';
    final room = _rooms[roomName];
    if (room != null) {
      PusherService.instance.unsubscribeFromCommunityRoom(room.id);
    }
    
    try {
      final url = Uri.parse('$_baseUrl/api/community-chat/rooms/$roomName/leave');
      await http.post(
        url, 
        headers: _headers(token),
        body: jsonEncode({'nickname': nickname ?? 'A user'})
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
  
  void _onRoomPusherEvent(dynamic event) {
    try {
      if (event != null && event['event'] != null) {
        final eventName = event['event'];
        final data = jsonDecode(event['data']);
        
        if (eventName == 'chat-message') {
          final msg = CommunityChatMessage.fromJson(data);
          final room = _rooms[msg.roomName]; // We added roomName relation in schema!
          if (room != null) {
            room.messages.add(msg);
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }
}
