import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Pusher channel subscriptions for the Mafia game.
///
/// Channels used:
///   • `game-{roomCode}`     — public room-wide events
///   • `room-{roomCode}`     — lobby-phase room events
///   • `private-{userId}`    — player's private events (role, cop results)
///   • `rooms`               — global room list events
///
/// The private channel requires auth via POST /api/game/pusher/auth.
class PusherService extends ChangeNotifier {
  PusherService._();
  static final PusherService instance = PusherService._();

  static const String _appKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: '9abb93acdbad87f7e0cb',
  );
  static const String _cluster = String.fromEnvironment(
    'PUSHER_CLUSTER',
    defaultValue: 'ap2',
  );
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nimbus-2k26-backend-olhw.onrender.com',
  );

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  // ─── EVENT STREAMS ──────────────────────────────────────────────────────────

  final _phaseController = StreamController<Map<String, dynamic>>.broadcast();
  final _roleController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameEndedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voteController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  final _investigationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reporterBroadcastController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _hitmanStrikeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reporterResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _nurseCheckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _actionReportController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _dayTimeUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  // Global room list events (for the browse rooms screen)
  final _roomOpenedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roomClosedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onPhaseResolved => _phaseController.stream;
  Stream<Map<String, dynamic>> get onRoleAssigned => _roleController.stream;
  Stream<Map<String, dynamic>> get onGameEnded => _gameEndedController.stream;
  Stream<Map<String, dynamic>> get onVoteUpdated => _voteController.stream;
  Stream<Map<String, dynamic>> get onPlayerJoined =>
      _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get onPlayerLeft => _playerLeftController.stream;
  Stream<Map<String, dynamic>> get onGameStarted =>
      _gameStartedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatController.stream;

  /// Cop only — private investigation result
  Stream<Map<String, dynamic>> get onInvestigationResult =>
      _investigationController.stream;

  /// Reporter broadcast — public, all players see it
  Stream<Map<String, dynamic>> get onReporterBroadcast =>
      _reporterBroadcastController.stream;

  /// Hitman has struck early — players in the hitman kill are eliminated
  Stream<Map<String, dynamic>> get onHitmanStrike =>
      _hitmanStrikeController.stream;

  /// Reporter private result — role of target player
  Stream<Map<String, dynamic>> get onReporterResult =>
      _reporterResultController.stream;

  /// Nurse check result — whether target is doctor
  Stream<Map<String, dynamic>> get onNurseCheckResult =>
      _nurseCheckController.stream;

  /// Public action report (mafia kill, bounty hunter kill, doctor save, etc)
  Stream<Map<String, dynamic>> get onActionReport =>
      _actionReportController.stream;
  Stream<Map<String, dynamic>> get onDayTimeUpdated =>
      _dayTimeUpdatedController.stream;

  Stream<Map<String, dynamic>> get onRoomOpened => _roomOpenedController.stream;
  Stream<Map<String, dynamic>> get onRoomClosed => _roomClosedController.stream;

  bool _connected = false;

  /// Whether Pusher is currently connected.
  bool get isConnected => _connected;
  String? _currentRoomCode;
  String? _currentUserId;

  // ─── CONNECT ────────────────────────────────────────────────────────────────

  Future<void> connect({
    required String roomCode,
    required String userId,
  }) async {
    if (_connected &&
        _currentRoomCode == roomCode &&
        _currentUserId == userId) {
      return; // Already connected to the right channels
    }

    await disconnect();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      await _pusher.init(
        apiKey: _appKey,
        cluster: _cluster,
        authEndpoint: '$_baseUrl/api/game/pusher/auth',
        authParams: {
          'headers': {'Authorization': 'Bearer $token'},
        },
        onError: (message, code, error) {
          debugPrint('[Pusher] Error $code: $message — $error');
        },
        onConnectionStateChange: (curr, prev) {
          debugPrint('[Pusher] $prev → $curr');
        },
      );

      await _pusher.connect();

      // ── Public game channel ────────────────────────────────────────────────
      await _pusher.subscribe(
        channelName: 'game-$roomCode',
        onEvent: _onRoomEvent,
      );

      // ── Lobby room channel ─────────────────────────────────────────────────
      await _pusher.subscribe(
        channelName: 'room-$roomCode',
        onEvent: _onLobbyEvent,
      );

      // ── Private player channel ─────────────────────────────────────────────
      await _pusher.subscribe(
        channelName: 'private-$userId',
        onEvent: _onPrivateEvent,
      );

      _connected = true;
      _currentRoomCode = roomCode;
      _currentUserId = userId;
    } catch (e) {
      debugPrint('[Pusher] Connect failed: $e');
      rethrow;
    }
  }

  // ─── DISCONNECT ─────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    if (!_connected) return;
    try {
      if (_currentRoomCode != null) {
        await _pusher.unsubscribe(channelName: 'game-$_currentRoomCode');
        await _pusher.unsubscribe(channelName: 'room-$_currentRoomCode');
      }
      if (_currentUserId != null) {
        await _pusher.unsubscribe(channelName: 'private-$_currentUserId');
      }
      await _pusher.disconnect();
    } catch (_) {}
    _connected = false;
    _currentRoomCode = null;
    _currentUserId = null;
  }

  // ─── GLOBAL ROOMS CHANNEL ───────────────────────────────────────────────────

  /// Subscribe to the global 'rooms' Pusher channel to get real-time
  /// room open/close events for the browse screen. Call on lobby entry.
  Future<void> subscribeRoomsChannel() async {
    try {
      await _pusher.subscribe(
        channelName: 'rooms',
        onEvent: _onGlobalRoomsEvent,
      );
    } catch (e) {
      debugPrint('[Pusher] Failed to subscribe to rooms channel: $e');
    }
  }

  Future<void> unsubscribeRoomsChannel() async {
    try {
      await _pusher.unsubscribe(channelName: 'rooms');
    } catch (_) {}
  }

  // ─── TEAM CHANNELS ──────────────────────────────────────────────────────────

  /// Subscribe to a private team channel (e.g. mafia, doc, citizen)
  Future<void> subscribeToTeamChannel(String roomCode, String team) async {
    final channelName = 'private-$team-$roomCode';
    try {
      await _pusher.subscribe(channelName: channelName, onEvent: _onRoomEvent);
      debugPrint('[Pusher] Subscribed to team channel: $channelName');
    } catch (e) {
      debugPrint('[Pusher] Failed to subscribe to $channelName: $e');
    }
  }

  Future<void> unsubscribeFromTeamChannel(String roomCode, String team) async {
    final channelName = 'private-$team-$roomCode';
    try {
      await _pusher.unsubscribe(channelName: channelName);
      debugPrint('[Pusher] Unsubscribed from team channel: $channelName');
    } catch (_) {}
  }

  // ─── EVENT HANDLERS ─────────────────────────────────────────────────────────

  Future<void> triggerLobbyChat(String roomCode, Map<String, dynamic> data) async {
    try {
      await _pusher.trigger(PusherEvent(
        channelName: 'private-lobby-$roomCode',
        eventName: 'client-chat-message',
        data: jsonEncode(data),
      ));
    } catch (e) {
      debugPrint('[Pusher] Trigger failed: $e');
    }
  }

  // pusher_channels_flutter ^2.x passes events as `dynamic` (PusherEvent),
  // so we accept dynamic and cast to avoid subtype errors at runtime.

  void _onRoomEvent(dynamic event) {
    final pusherEvent = event as PusherEvent;
    final data = _decode(pusherEvent.data);
    if (data == null) return;

    debugPrint('[Pusher] ${pusherEvent.eventName}: $data');

    switch (pusherEvent.eventName) {
      case 'phase-resolved':
        _phaseController.add(data);
        break;
      case 'game-ended':
        _gameEndedController.add(data);
        break;
      case 'vote-updated':
        _voteController.add(data);
        break;
      case 'player-joined':
        _playerJoinedController.add(data);
        break;
      case 'chat-message':
      case 'client-chat-message':
        _chatController.add(data);
        break;
      case 'reporter-broadcast':
        _reporterBroadcastController.add(data);
        break;
      case 'hitman-strike':
        _hitmanStrikeController.add(data);
        break;
      case 'action-report':
        _actionReportController.add(data);
        break;
      case 'day-time-updated':
        _dayTimeUpdatedController.add(data);
        break;
      case 'game-started':
        _gameStartedController.add(data);
        break;
      case 'player-left':
        _playerLeftController.add(data);
        break;
    }
  }

  /// Handles lobby-phase room channel events (room-{code}).
  /// Backend fires: player-joined, player-left, game-started here.
  void _onLobbyEvent(dynamic event) {
    final pusherEvent = event as PusherEvent;
    final data = _decode(pusherEvent.data);
    if (data == null) return;

    debugPrint('[Pusher][lobby] ${pusherEvent.eventName}: $data');

    switch (pusherEvent.eventName) {
      case 'player-joined':
        _playerJoinedController.add(data);
        break;
      case 'player-left':
        _playerLeftController.add(data);
        break;
      case 'chat-message':
      case 'client-chat-message':
        _chatController.add(data);
        break;
      case 'game-started':
        _gameStartedController.add(data);
        break;
    }
  }

  /// Handles global rooms channel events (rooms).
  void _onGlobalRoomsEvent(dynamic event) {
    final pusherEvent = event as PusherEvent;
    final data = _decode(pusherEvent.data);
    if (data == null) return;

    debugPrint('[Pusher][rooms] ${pusherEvent.eventName}: $data');

    switch (pusherEvent.eventName) {
      case 'room-opened':
        _roomOpenedController.add(data);
        break;
      case 'room-closed':
        _roomClosedController.add(data);
        break;
    }
  }

  void _onPrivateEvent(dynamic event) {
    final pusherEvent = event as PusherEvent;
    final data = _decode(pusherEvent.data);
    if (data == null) return;

    debugPrint('[Pusher][private] ${pusherEvent.eventName}: $data');

    switch (pusherEvent.eventName) {
      case 'role-assigned':
        _roleController.add(data);
        break;
      case 'investigation-result':
        _investigationController.add(data);
        break;
      case 'reporter-result':
        _reporterResultController.add(data);
        break;
      case 'nurse-check-result':
        _nurseCheckController.add(data);
        break;
    }
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── COMMUNITY CHAT ──────────────────────────────────────────────────────────

  Future<void> subscribeToGlobalCommunityChat(void Function(dynamic) onEvent) async {
    try {
      await _pusher.subscribe(
        channelName: 'community-global',
        onEvent: (e) {
          final ev = e as PusherEvent;
          onEvent({'event': ev.eventName, 'data': ev.data});
        },
      );
    } catch (_) {}
  }

  Future<void> subscribeToCommunityRoom(String roomId, void Function(dynamic) onEvent) async {
    try {
      await _pusher.subscribe(
        channelName: 'community-$roomId',
        onEvent: (e) {
          final ev = e as PusherEvent;
          onEvent({'event': ev.eventName, 'data': ev.data});
        },
      );
    } catch (_) {}
  }

  Future<void> unsubscribeFromCommunityRoom(String roomId) async {
    try {
      await _pusher.unsubscribe(channelName: 'community-$roomId');
    } catch (_) {}
  }

  @override
  void dispose() {
    disconnect();
    _phaseController.close();
    _roleController.close();
    _gameEndedController.close();
    _voteController.close();
    _playerJoinedController.close();
    _playerLeftController.close();
    _gameStartedController.close();
    _chatController.close();
    _investigationController.close();
    _reporterBroadcastController.close();
    _hitmanStrikeController.close();
    _reporterResultController.close();
    _nurseCheckController.close();
    _actionReportController.close();
    _dayTimeUpdatedController.close();
    _roomOpenedController.close();
    _roomClosedController.close();
    super.dispose();
  }
}
