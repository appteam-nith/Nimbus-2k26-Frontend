import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import '../services/game_api.dart';
import '../services/pusher_service.dart';

// ─── NAVIGATION KEYS ─────────────────────────────────────────────────────────
// These must be set by the app root so GameController can navigate
// without a BuildContext.

/// Global navigator key — set in MaterialApp.navigatorKey
final GlobalKey<NavigatorState> mafiaNavKey = GlobalKey<NavigatorState>();

// ─── GAME CONTROLLER ─────────────────────────────────────────────────────────

/// Central state manager for the Mafia game.
///
/// Lifecycle:
///   [init]         → call when entering game (from lobby or reconnect)
///   [dispose]      → call when leaving game (home, game over)
///
/// All Pusher events are handled here and translated into state + navigation.
class GameController extends ChangeNotifier {
  // ── Public state ────────────────────────────────────────────────────────────
  GameStatus status = GameStatus.LOBBY;
  GameRole? myRole;
  List<PlayerModel> players = [];
  String? winner; // "MAFIA" | "CITIZENS"
  String? roomCode;
  String? myUserId;
  int round = 0;
  bool isReconnecting = false;
  bool isLoading = false;
  String? error;
  DateTime? get phaseEndsAt => _phaseEndsAt;

  /// The player eliminated this round — set during REVEAL phase.
  PlayerModel? revealedPlayer;

  /// Timer countdown in seconds (mirrors backend phaseEndsAt).
  int timeRemaining = 0;

  /// Whether the local role card reveal animation has been shown.
  bool roleCardSeen = false;

  // ── Private ─────────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  DateTime? _phaseEndsAt;

  StreamSubscription<Map<String, dynamic>>? _phaseSub;
  StreamSubscription<Map<String, dynamic>>? _roleSub;
  StreamSubscription<Map<String, dynamic>>? _gameEndSub;
  StreamSubscription<Map<String, dynamic>>? _voteSub;
  StreamSubscription<Map<String, dynamic>>? _chatSub; // NEW

  final GameApi _api = GameApi.instance;
  final PusherService _pusher = PusherService.instance;

  // ─── INIT (fresh game start OR reconnect) ──────────────────────────────────

  /// Call this after joining/creating a room.
  /// [reconnect] = true skips the role-reveal screen and goes straight to
  /// the current phase screen.
  Future<void> init(String code, String userId,
      {bool reconnect = false}) async {
    roomCode = code;
    myUserId = userId;
    isReconnecting = reconnect;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // 1. Snapshot from REST
      final room = await _api.getRoomState(code);
      _applyRoomSnapshot(room);

      // 2. Persist for reconnect
      await _api.saveActiveRoom(code);

      // 3. Connect Pusher
      await _pusher.connect(roomCode: code, userId: userId);
      _listenToPusher();

      // 4. Start local countdown from server's timeRemaining
      if (room.phaseEndsAt != null) {
        _startCountdown(room.phaseEndsAt!);
      }

      isLoading = false;
      notifyListeners();

      // 5. Navigate to current phase
      if (reconnect) {
        _routeToCurrentPhase();
      } else if (status == GameStatus.NIGHT && myRole != null && !roleCardSeen) {
        _navigate('/mafia/role');
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  // ─── RECONNECT ──────────────────────────────────────────────────────────────

  /// Called from app startup. Checks SharedPrefs for a persisted room code,
  /// fetches room state, and routes to the correct screen.
  Future<bool> tryReconnect(String userId) async {
    final code = await _api.getActiveRoomCode();
    if (code == null) return false;

    try {
      final room = await _api.getRoomState(code);
      if (!room.isActive) {
        await _api.clearActiveRoom();
        return false;
      }
      await init(code, userId, reconnect: true);
      return true;
    } catch (_) {
      await _api.clearActiveRoom();
      return false;
    }
  }

  // ─── STATE APPLICATION ──────────────────────────────────────────────────────

  void _applyRoomSnapshot(RoomModel room) {
    status = room.status;
    myRole = room.myRole;
    players = room.players;
    winner = room.winner;
    round = room.round;
    revealedPlayer = room.eliminatedPlayer;
    _phaseEndsAt = room.phaseEndsAt;
    timeRemaining = room.timeRemaining ?? 0;
  }

  // ─── PUSHER SUBSCRIPTIONS ───────────────────────────────────────────────────

  void _listenToPusher() {
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _chatSub?.cancel();

    _phaseSub = _pusher.onPhaseResolved.listen(_handlePhaseResolved);
    _roleSub = _pusher.onRoleAssigned.listen(_handleRoleAssigned);
    _gameEndSub = _pusher.onGameEnded.listen(_handleGameEnded);
    _chatSub = _pusher.onChatMessage.listen((_) => notifyListeners()); // NEW
    _voteSub = _pusher.onVoteUpdated.listen((data) {
      // Vote count updates are handled by screens directly;
      // controller just notifies for state rebuild.
      notifyListeners();
    });
  }

  // ─── EVENT HANDLERS ─────────────────────────────────────────────────────────

  void _handlePhaseResolved(Map<String, dynamic> data) {
    final phase = data['phase'] as String? ?? '';
    round = data['round'] as int? ?? round;

    final phaseEndsAtRaw = data['phaseEndsAt'] as String?;
    _phaseEndsAt =
        phaseEndsAtRaw != null ? DateTime.tryParse(phaseEndsAtRaw) : null;

    // Update revealed player from eliminatedPlayerId
    final eliminatedId = data['eliminatedPlayerId'] as String?;
    revealedPlayer = eliminatedId != null
        ? players.cast<PlayerModel?>().firstWhere(
            (p) => p?.userId == eliminatedId,
            orElse: () => null,
          )
        : null;

    // Update a killed player from night resolution
    final killedId = data['killedPlayerId'] as String?;
    if (killedId != null) {
      players = players.map((p) {
        if (p.userId == killedId) {
          return p.copyWith(status: PlayerStatus.ELIMINATED);
        }
        return p;
      }).toList();
    }

    status = GameStatus.values.firstWhere(
      (s) => s.name == phase,
      orElse: () => status,
    );

    if (_phaseEndsAt != null) _startCountdown(_phaseEndsAt!);

    notifyListeners();
    _routeToCurrentPhase();
  }

  void _handleRoleAssigned(Map<String, dynamic> data) {
    final roleStr = data['role'] as String?;
    if (roleStr != null) {
      myRole = GameRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => GameRole.CITIZEN,
      );
      roleCardSeen = false;
      notifyListeners();
      _navigate('/mafia/role');
    }
  }

  void _handleGameEnded(Map<String, dynamic> data) {
    winner = data['winner'] as String?;
    status = GameStatus.ENDED;

    // Reveal all roles
    final rawPlayers = data['players'] as List<dynamic>? ?? [];
    players = rawPlayers
        .map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
        .toList();

    _stopCountdown();
    notifyListeners();

    // Clear persisted room — game is over
    _api.clearActiveRoom();

    _navigate('/mafia/game-over');
  }

  // ─── ROUTING ────────────────────────────────────────────────────────────────

  void _routeToCurrentPhase() {
    switch (status) {
      case GameStatus.NIGHT:
        if (myRole != null && !roleCardSeen) {
          _navigate('/mafia/role');
        } else {
          _navigate('/mafia/night');
        }
        break;
      case GameStatus.DISCUSSION:
        _navigate('/mafia/discussion');
        break;
      case GameStatus.VOTING:
        _navigate('/mafia/voting');
        break;
      case GameStatus.REVEAL:
        _navigate('/mafia/reveal');
        break;
      case GameStatus.ENDED:
        _navigate('/mafia/game-over');
        break;
      case GameStatus.LOBBY:
        break; // lobby handled by Dev 2
    }
  }

  void _navigate(String route) {
    final nav = mafiaNavKey.currentState;
    if (nav == null) return;
    // Push only if not already on that route
    nav.pushNamedAndRemoveUntil(route, (r) => false);
  }

  // ─── COUNTDOWN TIMER ────────────────────────────────────────────────────────

  void _startCountdown(DateTime endsAt) {
    _stopCountdown();
    _phaseEndsAt = endsAt;

    // Seed immediately
    timeRemaining =
        (endsAt.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    timeRemaining = timeRemaining.clamp(0, 999);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining =
          ((_phaseEndsAt!.difference(DateTime.now()).inMilliseconds) / 1000)
              .ceil();
      timeRemaining = remaining.clamp(0, 999);
      notifyListeners();
      if (timeRemaining <= 0) _stopCountdown();
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ─── ACTIONS ────────────────────────────────────────────────────────────────

  /// Sends a lynch vote or a special action (kill/save) to the API.
  Future<void> performAction(String targetId) async {
    String actionType = (status == GameStatus.VOTING) ? "VOTE" : "KILL";
    try {
      await _api.postAction(roomCode!, targetId, actionType);
    } catch (e) {
      debugPrint("Action Failed: $e");
    }
  }

  /// Mark role card as seen — call from RoleScreen's "Tap to continue".
  void markRoleCardSeen() {
    roleCardSeen = true;
    notifyListeners();
    _navigate('/mafia/night');
  }

  /// Full cleanup — call when player leaves game or hits Home.
  Future<void> leaveGame() async {
    _stopCountdown();
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _chatSub?.cancel();
    await _pusher.disconnect();
    await _api.clearActiveRoom();
    // Reset state
    status = GameStatus.LOBBY;
    myRole = null;
    players = [];
    winner = null;
    roomCode = null;
    roleCardSeen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopCountdown();
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}