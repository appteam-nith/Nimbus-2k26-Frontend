import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Pusher channel subscriptions for the Mafia game.
///
/// Channels used:
///   • `game-{roomCode}`     — public room-wide events
///   • `private-{userId}`    — player's private events (role, cop results)
///
/// The private channel requires auth via POST /api/game/pusher/auth.
class PusherService extends ChangeNotifier {
  PusherService._();
  static final PusherService instance = PusherService._();

  static const String _appKey =
      String.fromEnvironment('PUSHER_APP_KEY', defaultValue: '');
  static const String _cluster =
      String.fromEnvironment('PUSHER_CLUSTER', defaultValue: 'ap2');
  static const String _baseUrl =
      String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://nimbus-2k26-backend-2.onrender.com');

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
  final _chatController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _investigationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onPhaseResolved => _phaseController.stream;
  Stream<Map<String, dynamic>> get onRoleAssigned => _roleController.stream;
  Stream<Map<String, dynamic>> get onGameEnded => _gameEndedController.stream;
  Stream<Map<String, dynamic>> get onGameStarted => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get onVoteUpdated => _voteController.stream;
  Stream<Map<String, dynamic>> get onPlayerJoined =>
      _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatController.stream;

  /// Cop only — private investigation result
  Stream<Map<String, dynamic>> get onInvestigationResult =>
      _investigationController.stream;

  bool _connected = false;
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
    final token = prefs.getString('auth_token') ?? ''; // AuthProvider uses 'auth_token'

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

      // ── Public room channel ────────────────────────────────────────────────
      await _pusher.subscribe(
        channelName: 'game-$roomCode',
        onEvent: _onRoomEvent,
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

  // ─── EVENT HANDLERS ─────────────────────────────────────────────────────────

  void _onRoomEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher] \${event.eventName}: \$data');

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
      case 'chat-message':
        _chatController.add(data);
        break;
    }
  }

  void _onPrivateEvent(PusherEvent event) {
    final data = _decode(event.data);
    if (data == null) return;

    debugPrint('[Pusher][private] \${event.eventName}: \$data');

    switch (event.eventName) {
      case 'role-assigned':
        _roleController.add(data);
        break;
      case 'investigation-result':
        _investigationController.add(data);
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

  @override
  void dispose() {
    disconnect();
    _phaseController.close();
    _roleController.close();
    _gameEndedController.close();
    _gameStartedController.close();
    _voteController.close();
    _playerJoinedController.close();
    _chatController.close();
    _investigationController.close();
    super.dispose();
  }
}
