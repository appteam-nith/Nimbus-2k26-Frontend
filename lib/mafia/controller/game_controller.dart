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
///   [init]        → call when entering game (from lobby or reconnect)
///   [dispose]     → call when leaving game (home, game over)
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

  /// The player eliminated this round — set during REVEAL phase.
  /// Kept for backward compat with single-death RevealScreen.
  PlayerModel? revealedPlayer;

  /// All deaths that occurred during the night/day (0–N entries).
  /// Powers the morning reveal multi-card carousel.
  List<DeathEvent> morningDeaths = [];

  /// Set when a `reporter-broadcast` event fires. Cleared by the overlay
  /// after the player dismisses it.
  ReporterBroadcast? pendingBroadcast;

  /// Timer countdown in seconds (mirrors backend phaseEndsAt).
  int timeRemaining = 0;

  /// Whether the local role card reveal animation has been shown.
  bool roleCardSeen = false;

  // ─ Private ──────────────────────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  DateTime? _phaseEndsAt;

  StreamSubscription<Map<String, dynamic>>? _phaseSub;
  StreamSubscription<Map<String, dynamic>>? _roleSub;
  StreamSubscription<Map<String, dynamic>>? _gameEndSub;
  StreamSubscription<Map<String, dynamic>>? _voteSub;
  StreamSubscription<Map<String, dynamic>>? _reporterSub;
  StreamSubscription<Map<String, dynamic>>? _hitmanSub;

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
    _reporterSub?.cancel();
    _hitmanSub?.cancel();

    _phaseSub = _pusher.onPhaseResolved.listen(_handlePhaseResolved);
    _roleSub = _pusher.onRoleAssigned.listen(_handleRoleAssigned);
    _gameEndSub = _pusher.onGameEnded.listen(_handleGameEnded);
    _voteSub = _pusher.onVoteUpdated.listen((data) {
      notifyListeners();
    });
    _reporterSub =
        _pusher.onReporterBroadcast.listen(_handleReporterBroadcast);
    _hitmanSub = _pusher.onHitmanStrike.listen(_handleHitmanStrike);
  }

  // ─── EVENT HANDLERS ─────────────────────────────────────────────────────────

  void _handlePhaseResolved(Map<String, dynamic> data) {
    final phase = data['phase'] as String? ?? '';
    round = data['round'] as int? ?? round;

    final phaseEndsAtRaw = data['phaseEndsAt'] as String?;
    _phaseEndsAt =
        phaseEndsAtRaw != null ? DateTime.tryParse(phaseEndsAtRaw) : null;

    // ─ Parse multi-death array (new format) ─────────────────────────────────────
    final rawDeaths = data['deaths'] as List<dynamic>?;
    if (rawDeaths != null && rawDeaths.isNotEmpty) {
      morningDeaths = rawDeaths
          .map((d) => DeathEvent.fromJson(
              d as Map<String, dynamic>, players))
          .toList();
      // Mark eliminated players
      final deadIds = morningDeaths.map((d) => d.player.userId).toSet();
      players = players.map((p) {
        if (deadIds.contains(p.userId)) {
          return p.copyWith(status: PlayerStatus.ELIMINATED);
        }
        return p;
      }).toList();
    } else {
      // ─ Backward compat: single killedPlayerId ─────────────────────────────────
      final killedId = data['killedPlayerId'] as String?;
      if (killedId != null) {
        players = players.map((p) {
          if (p.userId == killedId) {
            return p.copyWith(status: PlayerStatus.ELIMINATED);
          }
          return p;
        }).toList();
        final dead = players.firstWhere(
          (p) => p.userId == killedId,
          orElse: () => PlayerModel(
              userId: killedId, name: '?', status: PlayerStatus.ELIMINATED),
        );
        morningDeaths = [
          DeathEvent(player: dead, cause: DeathCause.MAFIA_KILL)
        ];
      } else {
        morningDeaths = [];
      }
    }

    // Legacy single-player compat
    final eliminatedId = data['eliminatedPlayerId'] as String?;
    revealedPlayer = eliminatedId != null
        ? players.cast<PlayerModel?>().firstWhere(
            (p) => p?.userId == eliminatedId,
            orElse: () => null,
          )
        : morningDeaths.isNotEmpty
            ? morningDeaths.first.player
            : null;

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

    morningDeaths = [];
    pendingBroadcast = null;
    _stopCountdown();
    notifyListeners();

    // Clear persisted room — game is over
    _api.clearActiveRoom();

    _navigate('/mafia/game-over');
  }

  // ─ Reporter Broadcast ────────────────────────────────────────────────────────────

  void _handleReporterBroadcast(Map<String, dynamic> data) {
    final playerName = data['playerName'] as String? ?? '?';
    final roleStr = data['role'] as String? ?? '';
    final role = GameRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => GameRole.CITIZEN,
    );
    pendingBroadcast = ReporterBroadcast(playerName: playerName, role: role);
    notifyListeners();
  }

  /// Call from the overlay widget once the broadcast has been shown.
  void dismissBroadcast() {
    pendingBroadcast = null;
    notifyListeners();
  }

  // ─ Hitman Strike ───────────────────────────────────────────────────────────────────

  void _handleHitmanStrike(Map<String, dynamic> data) {
    // hitman-strike fires at T-5s; earlyDeaths are added to morningDeaths
    // when phase-resolved fires at T-0. Here we just update player statuses.
    final rawKilled = data['killed'] as List<dynamic>? ?? [];
    for (final entry in rawKilled) {
      final id = entry is Map ? entry['playerId'] as String? : entry as String?;
      if (id != null) {
        players = players.map((p) {
          if (p.userId == id) {
            return p.copyWith(status: PlayerStatus.ELIMINATED);
          }
          return p;
        }).toList();
      }
    }
    notifyListeners();
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
    _reporterSub?.cancel();
    _hitmanSub?.cancel();
    await _pusher.disconnect();
    await _api.clearActiveRoom();
    // Reset state
    status = GameStatus.LOBBY;
    myRole = null;
    players = [];
    winner = null;
    roomCode = null;
    roleCardSeen = false;
    morningDeaths = [];
    pendingBroadcast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopCountdown();
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _reporterSub?.cancel();
    _hitmanSub?.cancel();
    super.dispose();
  }
}

// ─── REPORTER BROADCAST DATA ──────────────────────────────────────────────────

/// Immutable data object set on [GameController.pendingBroadcast] when
/// a `reporter-broadcast` Pusher event arrives.
/// The [ReporterBroadcastOverlay] widget reads this and calls
/// [GameController.dismissBroadcast] once shown.
class ReporterBroadcast {
  final String playerName;
  final GameRole role;

  const ReporterBroadcast({required this.playerName, required this.role});
}
