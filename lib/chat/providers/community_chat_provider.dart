import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';

class CommunityChatProvider extends ChangeNotifier {
  static const String publicRoomName = 'Public Chat';
  static const String _prefsKey = 'community_chat_state_v1';

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

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _loadFromStorage();
    _ensurePublicRoom();
    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> createRoom({
    required String name,
    required String createdById,
    required String createdByName,
    required bool lockRoom,
    String? password,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Room name cannot be empty.';
    }

    final existingRoom = _findRoomCaseInsensitive(trimmedName);
    if (existingRoom != null) {
      return 'A room with this name already exists.';
    }

    if (lockRoom) {
      final trimmedPassword = (password ?? '').trim();
      if (trimmedPassword.length < 4) {
        return 'Password must be at least 4 characters.';
      }
    }

    final room = CommunityChatRoom(
      name: trimmedName,
      isPublic: false,
      createdById: createdById,
      createdByName: createdByName,
      isLocked: lockRoom,
      password: lockRoom ? (password ?? '').trim() : null,
      createdAt: DateTime.now(),
      messages: [
        CommunityChatMessage(
          senderNickname: 'System',
          text: 'Room created by $createdByName.',
          sentAt: DateTime.now(),
          isSystem: true,
        ),
      ],
    );

    _rooms[trimmedName] = room;
    await _persist();
    notifyListeners();
    return null;
  }

  bool verifyRoomPassword({
    required String roomName,
    required String password,
  }) {
    final room = roomByName(roomName);
    if (room == null) return false;
    if (!room.isLocked || room.isPublic) return true;
    return room.password == password;
  }

  Future<String?> updateRoomLock({
    required String roomName,
    required String requesterUserId,
    required bool shouldLock,
    String? password,
  }) async {
    final room = roomByName(roomName);
    if (room == null) return 'Room not found.';
    if (room.isPublic) return 'Public room cannot be locked.';
    if (room.createdById != requesterUserId) {
      return 'Only the room creator can change room lock settings.';
    }

    if (shouldLock) {
      final trimmedPassword = (password ?? '').trim();
      if (trimmedPassword.length < 4) {
        return 'Password must be at least 4 characters.';
      }
      room.isLocked = true;
      room.password = trimmedPassword;
      room.messages.add(
        CommunityChatMessage(
          senderNickname: 'System',
          text: 'This room is now locked.',
          sentAt: DateTime.now(),
          isSystem: true,
        ),
      );
    } else {
      room.isLocked = false;
      room.password = null;
      room.messages.add(
        CommunityChatMessage(
          senderNickname: 'System',
          text: 'This room is now unlocked.',
          sentAt: DateTime.now(),
          isSystem: true,
        ),
      );
    }

    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> sendMessage({
    required String roomName,
    required String senderNickname,
    required String text,
  }) async {
    final room = roomByName(roomName);
    if (room == null) return 'Room not found.';

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return 'Message cannot be empty.';

    final trimmedNickname = senderNickname.trim();
    if (trimmedNickname.isEmpty) return 'Nickname is required.';

    room.messages.add(
      CommunityChatMessage(
        senderNickname: trimmedNickname,
        text: trimmedText,
        sentAt: DateTime.now(),
      ),
    );

    await _persist();
    notifyListeners();
    return null;
  }

  CommunityChatRoom? _findRoomCaseInsensitive(String name) {
    final lowerName = name.toLowerCase();
    for (final room in _rooms.values) {
      if (room.name.toLowerCase() == lowerName) {
        return room;
      }
    }
    return null;
  }

  void _ensurePublicRoom() {
    final existingPublic = _findRoomCaseInsensitive(publicRoomName);
    if (existingPublic != null) {
      existingPublic.isLocked = false;
      existingPublic.password = null;
      if (existingPublic.name != publicRoomName) {
        _rooms.remove(existingPublic.name);
        _rooms[publicRoomName] = existingPublic;
      }
      return;
    }

    _rooms[publicRoomName] = CommunityChatRoom(
      name: publicRoomName,
      isPublic: true,
      createdById: 'system',
      createdByName: 'System',
      isLocked: false,
      password: null,
      createdAt: DateTime.now(),
      messages: [
        CommunityChatMessage(
          senderNickname: 'System',
          text: 'Welcome to the public room. This room is always open.',
          sentAt: DateTime.now(),
          isSystem: true,
        ),
      ],
    );
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final room = CommunityChatRoom.fromJson(item);
          if (room.name.trim().isNotEmpty) {
            _rooms[room.name] = room;
          }
        } else if (item is Map) {
          final room = CommunityChatRoom.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
          if (room.name.trim().isNotEmpty) {
            _rooms[room.name] = room;
          }
        }
      }
    } catch (_) {
      _rooms.clear();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _rooms.values.map((room) => room.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, encoded);
  }
}
