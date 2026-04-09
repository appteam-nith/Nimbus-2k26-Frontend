import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/player_model.dart';
import '../models/death_event.dart';
import '../models/action_report_model.dart';
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
  String roomSize = 'FIVE';
  int round = 0;
  bool isReconnecting = false;
  bool isLoading = false;
  bool isAdjustingDayTime = false;
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

  /// Set when an `action-report` event fires. Cleared by the overlay.
  ActionReport? pendingActionReport;

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

  /// Whether the Hitman has met the Mafia team.
  bool hitmanMetMafia = false;

  /// Whether the game is running in developer mode (bots fill empty slots, all roles visible).
  bool devMode = false;

  /// Deaths reported at the start of DISCUSSION (from NIGHT resolution).
  List<DeathEvent> nightDeaths = [];

  /// Hitman strike event — non-null when T-5s kill fires.
  Map<String, dynamic>? hitmanStrikeEvent;

  /// Live vote tally during VOTING phase: { playerId → voteCount }
  Map<String, int> voteTally = {};

  /// Cop investigation result — set when private Pusher event arrives.
  String? investigationResult;

  /// Reporter private result — role of investigated player.
  String? reporterResult;

  /// Nurse check result — whether the nurse found the doctor.
  bool? nurseCheckIsDoctor;

  /// Bounty Hunter's VIP user ID (so the BH can see who their VIP is).
  String? bountyVipUserId;

  /// Local player's day-time adjustment vote: -1 decrease, 0 neutral, +1 increase.
  int myDayTimeAdjustment = 0;

  /// Seconds changed by one alive player's adjustment vote.
  int dayTimeDeltaSeconds = 0;

  // ── Private ─────────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  DateTime? _phaseEndsAt;

  StreamSubscription<Map<String, dynamic>>? _phaseSub;
  StreamSubscription<Map<String, dynamic>>? _roleSub;
  StreamSubscription<Map<String, dynamic>>? _gameEndSub;
  StreamSubscription<Map<String, dynamic>>? _voteSub;
  StreamSubscription<Map<String, dynamic>>? _reporterSub;
  StreamSubscription<Map<String, dynamic>>? _hitmanSub;
  StreamSubscription<Map<String, dynamic>>? _investigationSub;
  StreamSubscription<Map<String, dynamic>>? _reporterResultSub;
  StreamSubscription<Map<String, dynamic>>? _nurseCheckSub;
  StreamSubscription<Map<String, dynamic>>? _actionReportSub;
  StreamSubscription<Map<String, dynamic>>? _dayTimeSub;

  final GameApi _api = GameApi.instance;
  final PusherService _pusher = PusherService.instance;

  // ─── INIT (fresh game start OR reconnect) ──────────────────────────────────

  /// Call this after joining/creating a room.
  /// [reconnect] = true skips the role-reveal screen and goes straight to
  /// the current phase screen.
  Future<void> init(
    String code,
    String userId, {
    bool reconnect = false,
  }) async {
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
      } else if (status == GameStatus.NIGHT &&
          myRole != null &&
          !roleCardSeen) {
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
    roomSize = room.roomSize;
    revealedPlayer = room.eliminatedPlayer;
    _phaseEndsAt = room.phaseEndsAt;
    timeRemaining = room.timeRemaining ?? 0;
    nurseMet = room.nurseMet;
    reporterUsed = room.reporterUsed;
    hitmanMetMafia = room.hitmanMetMafia;
    devMode = room.devMode;
    myDayTimeAdjustment = room.myDayTimeAdjustment;
    dayTimeDeltaSeconds = room.dayTimeDeltaSeconds;
  }

  // ─── PUSHER SUBSCRIPTIONS ───────────────────────────────────────────────────

  void _listenToPusher() {
    _phaseSub?.cancel();
    _roleSub?.cancel();
    _gameEndSub?.cancel();
    _voteSub?.cancel();
    _reporterSub?.cancel();
    _hitmanSub?.cancel();
    _investigationSub?.cancel();
    _reporterResultSub?.cancel();
    _nurseCheckSub?.cancel();
    _actionReportSub?.cancel();
    _dayTimeSub?.cancel();

    _phaseSub = _pusher.onPhaseResolved.listen(_handlePhaseResolved);
    _roleSub = _pusher.onRoleAssigned.listen(_handleRoleAssigned);
    _gameEndSub = _pusher.onGameEnded.listen(_handleGameEnded);
    _voteSub = _pusher.onVoteUpdated.listen(_handleVoteUpdated);
    _reporterSub = _pusher.onReporterBroadcast.listen(_handleReporterBroadcast);
    _hitmanSub = _pusher.onHitmanStrike.listen(_handleHitmanStrike);
    _investigationSub = _pusher.onInvestigationResult.listen(
      _handleInvestigationResult,
    );
    _reporterResultSub = _pusher.onReporterResult.listen(_handleReporterResult);
    _nurseCheckSub = _pusher.onNurseCheckResult.listen(_handleNurseCheckResult);
    _actionReportSub = _pusher.onActionReport.listen(_handleActionReport);
    _dayTimeSub = _pusher.onDayTimeUpdated.listen(_handleDayTimeUpdated);
  }

  // ─── EVENT HANDLERS ─────────────────────────────────────────────────────────

  void _handlePhaseResolved(Map<String, dynamic> data) {
    final phase = data['phase'] as String? ?? '';
    round = data['round'] as int? ?? round;

    final phaseEndsAtRaw = data['phaseEndsAt'] as String?;
    _phaseEndsAt = phaseEndsAtRaw != null
        ? DateTime.tryParse(phaseEndsAtRaw)
        : null;

    final rawDeaths = data['deaths'] as List<dynamic>?;
    if (rawDeaths != null && rawDeaths.isNotEmpty) {
      morningDeaths = rawDeaths
          .map((d) => DeathEvent.fromJson(d as Map<String, dynamic>, players))
          .toList();
      final deadUserIds = morningDeaths.map((d) => d.player.userId).toSet();
      final deadPlayerIds = morningDeaths.map((d) => d.player.playerId).toSet();
      players = players.map((p) {
        if (deadUserIds.contains(p.userId) ||
            deadPlayerIds.contains(p.playerId)) {
          return p.copyWith(status: PlayerStatus.ELIMINATED);
        }
        return p;
      }).toList();
    } else {
      final killedId = data['killedPlayerId'] as String?;
      if (killedId != null) {
        players = players.map((p) {
          if (p.userId == killedId || p.playerId == killedId) {
            return p.copyWith(status: PlayerStatus.ELIMINATED);
          }
          return p;
        }).toList();
        final dead = players.firstWhere(
          (p) => p.userId == killedId || p.playerId == killedId,
          orElse: () => PlayerModel(
            playerId: killedId,
            userId: killedId,
            name: '?',
            status: PlayerStatus.ELIMINATED,
          ),
        );
        morningDeaths = [
          DeathEvent(player: dead, cause: DeathCause.MAFIA_KILL),
        ];
      } else {
        morningDeaths = [];
      }
    }

    nightDeaths = morningDeaths;

    final rb = data['reporterBroadcast'];
    if (rb is Map<String, dynamic>) {
      final targetUserId = rb['targetUserId'] as String?;
      final exposedRoleStr = rb['exposedRole'] as String?;

      String playerName = '?';
      if (targetUserId != null) {
        try {
          final p = players.firstWhere((p) => p.userId == targetUserId);
          playerName = p.name;
        } catch (_) {}
      }

      final role = exposedRoleStr != null
          ? GameRole.values.firstWhere(
              (r) => r.name == exposedRoleStr,
              orElse: () => GameRole.CITIZEN,
            )
          : GameRole.CITIZEN;

      pendingBroadcast = ReporterBroadcast(playerName: playerName, role: role);
    }

    final eliminatedUserId = data['eliminatedPlayerUserId'] as String?;
    final eliminatedPlayerId = data['eliminatedPlayerId'] as String?;
    if (eliminatedUserId != null) {
      revealedPlayer = players.cast<PlayerModel?>().firstWhere(
        (p) => p?.userId == eliminatedUserId,
        orElse: () => null,
      );
    } else if (eliminatedPlayerId != null) {
      revealedPlayer = players.cast<PlayerModel?>().firstWhere(
        (p) => p?.playerId == eliminatedPlayerId,
        orElse: () => null,
      );
    } else if (morningDeaths.isNotEmpty) {
      revealedPlayer = morningDeaths.first.player;
    } else {
      revealedPlayer = null;
    }

    status = GameStatus.values.firstWhere(
      (s) => s.name == phase,
      orElse: () => status,
    );

    if (status == GameStatus.REVEAL &&
        revealedPlayer != null &&
        morningDeaths.isEmpty) {
      morningDeaths = [
        DeathEvent(
          player: revealedPlayer!.copyWith(status: PlayerStatus.ELIMINATED),
          cause: DeathCause.VOTE_ELIMINATION,
        ),
      ];
      players = players.map((p) {
        if (p.userId == revealedPlayer!.userId) {
          return p.copyWith(status: PlayerStatus.ELIMINATED);
        }
        return p;
      }).toList();
    }

    if (status == GameStatus.DISCUSSION) {
      final aliveCount = players.where((p) => p.isAlive).length;
      dayTimeDeltaSeconds = aliveCount > 0
          ? (120 / aliveCount).round().clamp(1, 120)
          : 0;
      myDayTimeAdjustment = 0;
    } else {
      myDayTimeAdjustment = 0;
      dayTimeDeltaSeconds = 0;
    }

    myVoteTarget = null;
    voteTally = {};
    hitmanStrikeEvent = null;
    investigationResult = null;
    reporterResult = null;
    nurseCheckIsDoctor = null;

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
    pendingActionReport = null;
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

  // ─ Action Report ────────────────────────────────────────────────────────────

  void _handleActionReport(Map<String, dynamic> data) {
    pendingActionReport = ActionReport.fromJson(data);
    notifyListeners();
  }

  /// Call from the overlay widget once the action report has been shown.
  void dismissActionReport() {
    pendingActionReport = null;
    notifyListeners();
  }

  // ─ Hitman Strike ───────────────────────────────────────────────────────────────────

  void _handleHitmanStrike(Map<String, dynamic> data) {
    // hitman-strike fires at T-5s. Backend sends { deaths: [{playerId, userId, killedBy}], hitmanMetMafia: bool }
    // Update player statuses immediately so the grid reflects kills before phase-resolved fires.
    final rawDeaths = data['deaths'] as List<dynamic>? ?? [];
    for (final entry in rawDeaths) {
      if (entry is! Map) continue;
      // Backend sends both playerId (internal DB id) and userId (user-facing id)
      final userId = entry['userId'] as String?;
      final playerId = entry['playerId'] as String?;
      players = players.map((p) {
        if ((userId != null && p.userId == userId) ||
            (playerId != null && p.playerId == playerId)) {
          return p.copyWith(status: PlayerStatus.ELIMINATED);
        }
        return p;
      }).toList();
    }
    if (myVoteTarget != null) {
      final selected = players.cast<PlayerModel?>().firstWhere(
        (p) => p?.userId == myVoteTarget,
        orElse: () => null,
      );
      if (selected == null || !selected.isAlive) {
        myVoteTarget = null;
      }
    }

    // Set the event so the _HitmanStrikeOverlay in night_screen.dart renders
    hitmanStrikeEvent = data;

    // Update hitmanMetMafia flag if relevant
    final metMafia = data['hitmanMetMafia'] as bool? ?? false;
    if (metMafia) hitmanMetMafia = true;

    notifyListeners();
  }

  // ─ Vote Updated (with tally) ──────────────────────────────────────────────────

  void _handleVoteUpdated(Map<String, dynamic> data) {
    // Backend sends tally as { playerId: count } map
    final rawTally = data['tally'] as Map<String, dynamic>?;
    if (rawTally != null) {
      voteTally = rawTally.map((k, v) => MapEntry(k, v is int ? v : 0));
    }
    notifyListeners();
  }

  // ─ Cop Investigation Result ──────────────────────────────────────────────────

  void _handleInvestigationResult(Map<String, dynamic> data) {
    investigationResult = data['result'] as String?;
    notifyListeners();
  }

  // ─ Reporter Private Result ──────────────────────────────────────────────────

  void _handleReporterResult(Map<String, dynamic> data) {
    reporterResult = data['role'] as String?;
    notifyListeners();
  }

  // ─ Nurse Check Result ──────────────────────────────────────────────────────

  void _handleNurseCheckResult(Map<String, dynamic> data) {
    nurseCheckIsDoctor = data['isDoctor'] as bool? ?? false;
    notifyListeners();
  }

  void _handleDayTimeUpdated(Map<String, dynamic> data) {
    final phase = data['phase'] as String?;
    if (phase != null && phase != 'DISCUSSION') return;

    final phaseEndsAtRaw = data['phaseEndsAt'] as String?;
    if (phaseEndsAtRaw != null) {
      _phaseEndsAt = DateTime.tryParse(phaseEndsAtRaw);
      if (_phaseEndsAt != null) {
        _startCountdown(_phaseEndsAt!);
      }
    }

    final delta = data['deltaSeconds'];
    if (delta is int) {
      dayTimeDeltaSeconds = delta;
    } else if (delta is num) {
      dayTimeDeltaSeconds = delta.round();
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
    nav.pushNamedAndRemoveUntil(route, (r) => r.isFirst);
  }

  // ─── COUNTDOWN TIMER ────────────────────────────────────────────────────────

  void _startCountdown(DateTime endsAt) {
    _stopCountdown();
    _phaseEndsAt = endsAt;

    // Seed immediately
    timeRemaining = (endsAt.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil();
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

  /// Sets the local user's selected voting target.
  void setVoteTarget(String? userId) {
    if (userId != null) {
      final target = players.cast<PlayerModel?>().firstWhere(
        (p) => p?.userId == userId,
        orElse: () => null,
      );
      if (target == null || !target.isAlive) {
        myVoteTarget = null;
        notifyListeners();
        return;
      }
    }

    if (myVoteTarget == userId) {
      myVoteTarget = null; // Tap again to deselect
    } else {
      myVoteTarget = userId;
    }
    notifyListeners();
  }

  void clearHitmanStrike() {
    hitmanStrikeEvent = null;
    notifyListeners();
  }

  Future<void> adjustDiscussionTime(int adjustment) async {
    if (roomCode == null) return;
    if (status != GameStatus.DISCUSSION) return;
    if (![-1, 0, 1].contains(adjustment)) return;

    final me = players.firstWhere(
      (p) => p.userId == myUserId,
      orElse: () => const PlayerModel(
        playerId: '',
        userId: '',
        name: '',
        status: PlayerStatus.ELIMINATED,
      ),
    );
    if (!me.isAlive) return;

    try {
      isAdjustingDayTime = true;
      error = null;
      notifyListeners();

      final result = await _api.adjustDayTime(roomCode!, adjustment);
      final phaseEndsAtRaw = result['phaseEndsAt'] as String?;
      if (phaseEndsAtRaw != null) {
        _phaseEndsAt = DateTime.tryParse(phaseEndsAtRaw);
        if (_phaseEndsAt != null) {
          _startCountdown(_phaseEndsAt!);
        }
      }

      final myAdjustment = result['adjustment'];
      if (myAdjustment is int) {
        myDayTimeAdjustment = myAdjustment;
      } else if (myAdjustment is num) {
        myDayTimeAdjustment = myAdjustment.round();
      }

      final delta = result['deltaSeconds'];
      if (delta is int) {
        dayTimeDeltaSeconds = delta;
      } else if (delta is num) {
        dayTimeDeltaSeconds = delta.round();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isAdjustingDayTime = false;
      notifyListeners();
    }
  }

  /// Submits the vote via the API.
  /// If [overrideTargetMeta] is provided (for Hitman), it's sent as target_meta.
  Future<String?> submitVote(
    String voteType, {
    bool isSkip = false,
    Map<String, dynamic>? overrideTargetMeta,
  }) async {
    if (roomCode == null) return null;

    String? targetId;
    if (!isSkip) {
      if (myVoteTarget != null) {
        targetId = myVoteTarget;
      } else if (overrideTargetMeta == null) {
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
        targetId: targetId,
        targetMeta: overrideTargetMeta,
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
    _reporterSub?.cancel();
    _hitmanSub?.cancel();
    _investigationSub?.cancel();
    _reporterResultSub?.cancel();
    _nurseCheckSub?.cancel();
    _actionReportSub?.cancel();
    _dayTimeSub?.cancel();
    await _pusher.disconnect();
    await _api.clearActiveRoom();
    // Reset state
    status = GameStatus.LOBBY;
    myRole = null;
    players = [];
    winner = null;
    roomCode = null;
    roomSize = 'FIVE';
    roleCardSeen = false;
    morningDeaths = [];
    pendingBroadcast = null;
    pendingActionReport = null;
    myVoteTarget = null;
    voteTally = {};
    nightDeaths = [];
    hitmanStrikeEvent = null;
    nurseMet = false;
    reporterUsed = false;
    hitmanMetMafia = false;
    investigationResult = null;
    reporterResult = null;
    nurseCheckIsDoctor = null;
    bountyVipUserId = null;
    myDayTimeAdjustment = 0;
    dayTimeDeltaSeconds = 0;
    isAdjustingDayTime = false;
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
    _investigationSub?.cancel();
    _reporterResultSub?.cancel();
    _nurseCheckSub?.cancel();
    _actionReportSub?.cancel();
    _dayTimeSub?.cancel();
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
