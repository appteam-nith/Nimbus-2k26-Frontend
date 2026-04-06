import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import '../models/death_event.dart';
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

  /// The player the current user has selected to vote for.
  String? myVoteTarget;

  /// Whether the Nurse has found the Doctor yet (used to update Nurse UI).
  bool nurseMet = false;

  /// Whether the Reporter has already used their one-time broadcast ability.
  bool reporterUsed = false;

  /// Whether the game is running in developer mode (bots fill empty slots, all roles visible).
  bool devMode = false;

  /// Deaths reported at the start of DISCUSSION (from NIGHT resolution).
  List<DeathEvent> nightDeaths = [];

  /// Reporter broadcast — non-null if a reporter exposed a player this round.
  Map<String, dynamic>? reporterBroadcast;

  /// Hitman strike event — non-null when T-5s kill fires.
  Map<String, dynamic>? hitmanStrikeEvent;

  // ── Private ─────────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  DateTime? _phaseEndsAt;

  StreamSubscription<Map<String, dynamic>>? _phaseSub;
  StreamSubscription<Map<String, dynamic>>? _roleSub;
  StreamSubscription<Map<String, dynamic>>? _gameEndSub;
  StreamSubscription<Map<String, dynamic>>? _voteSub;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<Map<String, dynamic>>? _hitmanStrikeSub; // NEW

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
    nurseMet = room.nurseMet;
    reporterUsed = room.reporterUsed;
    devMode = room.devMode;
  }

  // ─── PUSHER SUBSCRIPTIONS ───────────────────────────────────────────────────

  void _listenToPusher() {
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _chatSub?.cancel();
    _hitmanStrikeSub?.cancel();

    _phaseSub = _pusher.onPhaseResolved.listen(_handlePhaseResolved);
    _roleSub = _pusher.onRoleAssigned.listen(_handleRoleAssigned);
    _gameEndSub = _pusher.onGameEnded.listen(_handleGameEnded);
    _chatSub = _pusher.onChatMessage.listen((_) => notifyListeners());
    _hitmanStrikeSub = _pusher.onHitmanStrike.listen(_handleHitmanStrike);
    _voteSub = _pusher.onVoteUpdated.listen((data) {
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

    // ── Parse deaths array (NIGHT → DISCUSSION transition) ─────────────────
    final rawDeaths = data['deaths'] as List<dynamic>?;
    if (rawDeaths != null && rawDeaths.isNotEmpty) {
      nightDeaths = rawDeaths
          .map((d) => DeathEvent.fromJson(d as Map<String, dynamic>))
          .toList();
      // Mark those players as ELIMINATED in local state
      final deadUserIds = nightDeaths.map((d) => d.userId).toSet();
      players = players.map((p) {
        if (deadUserIds.contains(p.userId)) {
          return p.copyWith(status: PlayerStatus.ELIMINATED);
        }
        return p;
      }).toList();
    } else {
      nightDeaths = [];
    }

    // ── Reporter broadcast ──────────────────────────────────────────────────
    final rb = data['reporterBroadcast'];
    reporterBroadcast = (rb is Map<String, dynamic>) ? rb : null;

    // ── Update revealed player from eliminatedPlayerId (VOTING → REVEAL) ───
    final eliminatedId = data['eliminatedPlayerId'] as String?;
    revealedPlayer = eliminatedId != null
        ? players.cast<PlayerModel?>().firstWhere(
            (p) => p?.userId == eliminatedId,
            orElse: () => null,
          )
        : null;

    status = GameStatus.values.firstWhere(
      (s) => s.name == phase,
      orElse: () => status,
    );

    // Reset local vote target when phase changes
    myVoteTarget = null;
    hitmanStrikeEvent = null; // clear between rounds

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
      // Subscribe to team channel now that role is known
      if (roomCode != null) {
        _pusher.subscribeTeamChannel(roleStr, roomCode!);
      }
      _navigate('/mafia/role');
    }
  }

  void _handleHitmanStrike(Map<String, dynamic> data) {
    hitmanStrikeEvent = data;
    notifyListeners();
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

  /// Sets the local user's selected voting target.
  void setVoteTarget(String? userId) {
    if (myVoteTarget == userId) {
      myVoteTarget = null; // Map tap again to deselect
    } else {
      myVoteTarget = userId;
    }
    notifyListeners();
  }

  /// Submits the vote via the API.
  /// If [overrideTargets] or [overrideRoles] are provided, they are used instead of [myVoteTarget].
  Future<String?> submitVote(
    String voteType, {
    bool isSkip = false,
    List<String>? overrideTargets,
    List<String>? overrideRoles,
  }) async {
    if (roomCode == null) return null;
    
    List<String>? targets = overrideTargets;
    if (targets == null && !isSkip) {
      if (myVoteTarget != null) {
        targets = [myVoteTarget!];
      } else {
        error = 'Please select a player first.';
        notifyListeners();
        return null;
      }
    }

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _api.submitVote(
        roomCode!, 
        voteType,
        targets: targets,
        roles: overrideRoles,
      );
      
      isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Full cleanup — call when player leaves game or hits Home.
  Future<void> leaveGame() async {
    _stopCountdown();
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _chatSub?.cancel();
    _hitmanStrikeSub?.cancel();
    await _pusher.disconnect();
    await _api.clearActiveRoom();
    // Reset state
    status = GameStatus.LOBBY;
    myRole = null;
    players = [];
    winner = null;
    roomCode = null;
    roleCardSeen = false;
    myVoteTarget = null;
    nightDeaths = [];
    reporterBroadcast = null;
    hitmanStrikeEvent = null;
    nurseMet = false;
    reporterUsed = false;
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
    _hitmanStrikeSub?.cancel();
    super.dispose();
  }
}