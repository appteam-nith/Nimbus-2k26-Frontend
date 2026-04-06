import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Pusher channel subscriptions for the Mafia game.
///
/// Channels used:
///   • `game-{roomCode}`           — public room-wide events
///   • `private-{userId}`          — player's private events (role, cop results)
///   • `private-mafia-{roomCode}`  — mafia team chat (MAFIA + met HITMAN)
///   • `private-doc-{roomCode}`    — doc-nurse chat (DOCTOR + met NURSE)
///   • `private-hitman-{roomCode}` — hitman-mafia coordination channel
///
/// The private channels require auth via POST /api/game/pusher/auth.
class PusherService extends ChangeNotifier {
  PusherService._();
  static final PusherService instance = PusherService._();

  bool get isConnected => _connected;
  static const String _appKey =
      String.fromEnvironment('PUSHER_APP_KEY', defaultValue: '');
  static const String _cluster =
      String.fromEnvironment('PUSHER_CLUSTER', defaultValue: 'ap2');
  static const String _baseUrl =
      String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://nimbus-2k26-backend-olhw.onrender.com');

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  // ─── EVENT STREAMS ──────────────────────────────────────────────────────────

  final _phaseController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roleController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameEndedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voteController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _investigationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _hitmanStrikeController =
      StreamController<Map<String, dynamic>>.broadcast();
  // Global room list events (for the browse rooms screen)
  final _roomOpenedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roomClosedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onPhaseResolved => _phaseController.stream;
  Stream<Map<String, dynamic>> get onRoleAssigned => _roleController.stream;
  Stream<Map<String, dynamic>> get onGameEnded => _gameEndedController.stream;
  Stream<Map<String, dynamic>> get onGameStarted => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get onVoteUpdated => _voteController.stream;
  Stream<Map<String, dynamic>> get onPlayerJoined =>
      _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get onPlayerLeft =>
      _playerLeftController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatController.stream;
  Stream<Map<String, dynamic>> get onHitmanStrike =>
      _hitmanStrikeController.stream;
  Stream<Map<String, dynamic>> get onRoomOpened => _roomOpenedController.stream;
  Stream<Map<String, dynamic>> get onRoomClosed => _roomClosedController.stream;

  /// Cop only — private investigation result
  Stream<Map<String, dynamic>> get onInvestigationResult =>
      _investigationController.stream;

  bool _connected = false;
  String? _currentRoomCode;
  String? _currentUserId;

  // Track which team channels are subscribed
  final Set<String> _subscribedTeamChannels = {};

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

      // ── Public room channel (game events: phase-resolved etc) ──────────────
      await _pusher.subscribe(
        channelName: 'game-$roomCode',
        onEvent: _onRoomEvent,
      );

      // ── Lobby room channel (join/leave/start during LOBBY phase) ────────────
      // Backend fires player-joined, player-left, game-started on room-{code}
      await _pusher.subscribe(
        channelName: 'room-$roomCode',
        onEvent: _onLobbyEvent,
      );

      // ── Private player channel ───────────────────────────────────────────
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

  // ─── TEAM CHANNEL SUBSCRIPTION ──────────────────────────────────────────────

  /// Called from GameController after role is assigned.
  /// Subscribes to the appropriate private team channel based on role.
  Future<void> subscribeTeamChannel(String role, String roomCode) async {
    if (!_connected) return;

    String? channelName;

    switch (role) {
      case 'MAFIA':
      case 'MAFIA_HELPER':
        channelName = 'private-mafia-$roomCode';
        break;
      case 'DOCTOR':
      case 'NURSE':
        channelName = 'private-doc-$roomCode';
        break;
      case 'HITMAN':
        // Hitman subscribes to both mafia and hitman channels.
        // The mafia channel is only usable once hitman meets mafia (enforced by backend).
        channelName = 'private-hitman-$roomCode';
        break;
      default:
        return; // Citizens, Cop, etc. have no team channel
    }

    if (_subscribedTeamChannels.contains(channelName)) return;

    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: _onTeamChatEvent,
      );
      _subscribedTeamChannels.add(channelName);
      debugPrint('[Pusher] Subscribed to team channel: $channelName');
    } catch (e) {
      debugPrint('[Pusher] Failed to subscribe to $channelName: $e');
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
      // Unsubscribe from all team channels
      for (final ch in _subscribedTeamChannels) {
        try {
          await _pusher.unsubscribe(channelName: ch);
        } catch (_) {}
      }
      _subscribedTeamChannels.clear();
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
    if (!_connected) return;
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

  // ─── EVENT HANDLERS ─────────────────────────────────────────────────────────

  void _onRoomEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher] ${event.eventName}: $data');

    switch (event.eventName) {
      case 'game-started':
        _gameStartedController.add(data);
        break;
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
      case 'player-left':
        _playerLeftController.add(data);
        break;
      case 'chat-message':
        _chatController.add(data);
        break;
      case 'hitman-strike':
        _hitmanStrikeController.add(data);
        break;
    }
  }

  /// Handles lobby-phase room channel events (room-{code}).
  /// Backend fires: player-joined, player-left, game-started here.
  void _onLobbyEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher][lobby] ${event.eventName}: $data');

    switch (event.eventName) {
      case 'player-joined':
        _playerJoinedController.add(data);
        break;
      case 'player-left':
        _playerLeftController.add(data);
        break;
      case 'game-started':
        _gameStartedController.add(data);
        break;
    }
  }

  /// Handles global rooms channel events (rooms).
  void _onGlobalRoomsEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher][rooms] ${event.eventName}: $data');

    switch (event.eventName) {
      case 'room-opened':
        _roomOpenedController.add(data);
        break;
      case 'room-closed':
        _roomClosedController.add(data);
        break;
    }
  }

  void _onPrivateEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher][private] ${event.eventName}: $data');

    switch (event.eventName) {
      case 'role-assigned':
        _roleController.add(data);
        break;
      case 'investigation-result':
        _investigationController.add(data);
        break;
    }
  }

  /// Handles team chat channels (mafia, doc, hitman).
  /// All team chat re-routes to the global chat stream with an enriched payload.
  void _onTeamChatEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher][team] ${event.eventName}: $data');

    if (event.eventName == 'chat-message') {
      _chatController.add(data);
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

  @override
  void dispose() {
    disconnect();
    _phaseController.close();
    _roleController.close();
    _gameEndedController.close();
    _gameStartedController.close();
    _voteController.close();
    _playerJoinedController.close();
    _playerLeftController.close();
    _chatController.close();
    _investigationController.close();
    _hitmanStrikeController.close();
    _roomOpenedController.close();
    _roomClosedController.close();
    super.dispose();
  }
}
