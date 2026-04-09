import 'dart:async';
import '../../../widgets/nimbus_city_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/game_controller.dart';
import '../models/chat_model.dart';
import '../models/player_model.dart';
import '../services/game_api.dart';
import '../services/pusher_service.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────────

const _bg = Color(0xFF0D121B);
const _surface = Color(0xFF161D2B);
const _card = Color(0xFF1C2537);
const _accent = Color(0xFF7C3AED); // purple
const _accentGlow = Color(0xFF9D5EF5);
const _red = Color(0xFFEF4444);
const _gold = Color(0xFFF59E0B);
const _textPrimary = Color(0xFFEEF2FF);
const _textSecondary = Color(0xFF94A3B8);
const _border = Color(0xFF263352);

// ─── SCREEN ───────────────────────────────────────────────────────────────────

/// Dev 2 — Lobby screen.
///
/// Phase A (entry): Create or Join a room.
/// Phase B (waiting room): Live player list + Start Game (host only).
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _inRoom = false;
  String? _roomCode;
  String? _myUserId;
  bool _isHost = false;
  String _roomSize = 'FIVE'; // FIVE | EIGHT | TWELVE
  List<PlayerModel> _players = [];
  bool _loading = false;
  String? _error;

  // Browse Rooms tab
  int _entryTab = 0; // 0 = Create/Join, 1 = Browse
  List<Map<String, dynamic>> _openRooms = [];
  bool _roomsLoading = false;

  // Developer Mode
  bool _devMode = false;
  GameRole? _devHostRole;

  StreamSubscription<Map<String, dynamic>>? _joinSub;
  StreamSubscription<Map<String, dynamic>>? _leaveSub;
  StreamSubscription<Map<String, dynamic>>? _startSub;
  StreamSubscription<Map<String, dynamic>>? _roomOpenedSub;
  StreamSubscription<Map<String, dynamic>>? _roomClosedSub;

  final GameApi _api = GameApi.instance;
  final PusherService _pusher = PusherService.instance;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadMyUserId();
  }

  Future<void> _loadMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // user_id stored by AuthProvider after login
    setState(() => _myUserId = prefs.getString('user_id'));
  }

  @override
  void dispose() {
    _joinSub?.cancel();
    _leaveSub?.cancel();
    _startSub?.cancel();
    _roomOpenedSub?.cancel();
    _roomClosedSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Pusher lobby subscriptions ─────────────────────────────────────────────

  void _subscribeLobbyEvents() {
    _joinSub?.cancel();
    _leaveSub?.cancel();
    _startSub?.cancel();

    // player-joined → add to list
    _joinSub = _pusher.onPlayerJoined.listen((data) {
      final userId = data['userId'] as String?;
      final name = data['name'] as String? ?? 'Unknown';
      if (userId == null) return;
      final already = _players.any((p) => p.userId == userId);
      if (!already) {
        setState(() {
          _players = [
            ..._players,
            PlayerModel(
              playerId: userId,
              userId: userId,
              name: name,
              status: PlayerStatus.ALIVE,
            ),
          ];
        });
      }
    });

    // player-left → remove from list
    _leaveSub = _pusher.onPlayerLeft.listen((data) {
      final userId = data['userId'] as String?;
      final newHostId = data['newHostId'] as String?;
      if (userId == null) return;
      setState(() {
        _players.removeWhere((p) => p.userId == userId);
        if (newHostId != null && newHostId == _myUserId) {
          _isHost = true;
        }
      });
    });

    // game-started → GameController takes over and navigates to role screen
    _startSub = _pusher.onGameStarted.listen((data) async {
      if (!mounted || _roomCode == null || _myUserId == null) return;
      final gc = context.read<GameController>();
      // init() fetches room state, connects Pusher fully, then routes to /mafia/role
      await gc.init(_roomCode!, _myUserId!);
    });
  }

  // ── Browse rooms realtime subscriptions ──────────────────────────────────

  void _subscribeBrowseEvents() {
    _roomOpenedSub?.cancel();
    _roomClosedSub?.cancel();

    _roomOpenedSub = _pusher.onRoomOpened.listen((data) {
      if (!mounted) return;
      final code = data['roomCode'] as String?;
      if (code == null) return;
      setState(() {
        // Upsert: update if exists, add if new
        final idx = _openRooms.indexWhere((r) => r['roomCode'] == code);
        if (idx >= 0) {
          _openRooms[idx] = data;
        } else {
          _openRooms = [data, ..._openRooms];
        }
      });
    });

    _roomClosedSub = _pusher.onRoomClosed.listen((data) {
      if (!mounted) return;
      final code = data['roomCode'] as String?;
      if (code == null) return;
      setState(() => _openRooms.removeWhere((r) => r['roomCode'] == code));
    });
  }

  Future<void> _loadOpenRooms() async {
    setState(() => _roomsLoading = true);
    try {
      final rooms = await _api.listRooms();
      if (mounted) setState(() => _openRooms = rooms);
    } catch (_) {
      // Fail silently — UI shows empty state
    } finally {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _createRoom() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await _api.createRoom(_roomSize);
      await _enterRoom(code, isHost: true);
    } on GameApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom(String code) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.joinRoom(code.toUpperCase());
      await _enterRoom(code.toUpperCase(), isHost: false);
    } on GameApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _enterRoom(String code, {required bool isHost}) async {
    // Fetch full snapshot (includes my player + all existing players)
    final room = await _api.getRoomState(code);
    await _api.saveActiveRoom(code);

    // Connect Pusher to lobby channels
    if (_myUserId != null) {
      await _pusher.connect(roomCode: code, userId: _myUserId!);
    }
    _subscribeLobbyEvents();

    setState(() {
      _roomCode = code;
      _isHost = isHost;
      _roomSize = room.roomSize;
      _players = room.players;
      _inRoom = true;
    });
  }

  Future<void> _startGame() async {
    if (_roomCode == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.startGame(
        _roomCode!,
        devMode: _devMode,
        devHostRole: _devHostRole?.name,
      );
      // The backend broadcasts 'game-started' via Pusher.
      // _startSub in _subscribeLobbyEvents handles navigation for ALL players
      // (including the host), so nothing more to do here.
    } on GameApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leaveRoomConfirmed() async {
    if (_roomCode != null) {
      _api.leaveRoom(_roomCode!);
    }
    _joinSub?.cancel();
    _leaveSub?.cancel();
    _startSub?.cancel();
    _pusher.disconnect();
    _api.clearActiveRoom();
    setState(() {
      _inRoom = false;
      _roomCode = null;
      _isHost = false;
      _players = [];
      _error = null;
    });
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave Room?',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          _isHost
              ? 'You are the host. Leaving will transfer host or delete the room if you are the last player.'
              : 'Are you sure you want to leave this room?',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _red),
            child: const Text(
              'Leave',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await _leaveRoomConfirmed();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int get _maxPlayers {
    switch (_roomSize) {
      case 'EIGHT':
        return 8;
      case 'TWELVE':
        return 12;
      default:
        return 5;
    }
  }

  bool get _roomFull => _players.length >= _maxPlayers;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_inRoom,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _inRoom) {
          await _leaveRoom();
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(child: _inRoom ? _buildWaitingRoom() : _buildEntry()),
      ),
    );
  }

  // ░░░░░░░░░░░░░░░░░░░░░░░░  PHASE A — ENTRY  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

  Widget _buildEntry() {
    return Column(
      children: [
        // ── Tab bar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              _EntryTab(
                label: 'Play',
                icon: Icons.gamepad_outlined,
                selected: _entryTab == 0,
                onTap: () => setState(() => _entryTab = 0),
              ),
              const SizedBox(width: 10),
              _EntryTab(
                label: 'Browse Rooms',
                icon: Icons.search_rounded,
                selected: _entryTab == 1,
                onTap: () {
                  setState(() => _entryTab = 1);
                  _loadOpenRooms();
                  _subscribeBrowseEvents();
                },
              ),
            ],
          ),
        ),
        Expanded(child: _entryTab == 0 ? _buildPlayTab() : _buildBrowseTab()),
      ],
    );
  }

  Widget _buildPlayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const SizedBox(height: 32),
          _buildHeroHeader(),
          const SizedBox(height: 40),
          if (_error != null) _buildError(_error!),
          _buildCreateCard(),
          const SizedBox(height: 16),
          _buildJoinCard(),
          const SizedBox(height: 40),
          _buildRulesHint(),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    if (_roomsLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_openRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'No open rooms',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first — create a room!',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Create Room',
              icon: Icons.add,
              loading: false,
              onTap: () => setState(() => _entryTab = 0),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadOpenRooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _openRooms.length,
        itemBuilder: (_, i) {
          final r = _openRooms[i];
          final code = r['roomCode'] as String? ?? '';
          final size = r['roomSize'] as String? ?? 'FIVE';
          final count = r['playerCount'] as int? ?? 0;
          final max = r['maxPlayers'] as int? ?? 5;
          final isFull = count >= max;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: isFull ? null : () => _joinRoom(code),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFull ? _border : _accent.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    // Room size icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        size == 'FIVE'
                            ? '5'
                            : size == 'EIGHT'
                            ? '8'
                            : '12',
                        style: const TextStyle(
                          color: _accentGlow,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$count / $max players',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'FULL',
                          style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'JOIN',
                          style: TextStyle(
                            color: _accentGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textSecondary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(scale: _pulse, child: NimbusCityLogo(size: 72)),
        const SizedBox(height: 20),
        const Text(
          'Nimbus City',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Deceive. Deduce. Survive.',
          style: TextStyle(color: _textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildCreateCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: _accentGlow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Room',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Host a new game for your group',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Room size',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SizeChip(
                label: '5',
                sublabel: 'Quick',
                selected: _roomSize == 'FIVE',
                onTap: () => setState(() => _roomSize = 'FIVE'),
              ),
              const SizedBox(width: 10),
              _SizeChip(
                label: '8',
                sublabel: 'Standard',
                selected: _roomSize == 'EIGHT',
                onTap: () => setState(() => _roomSize = 'EIGHT'),
              ),
              const SizedBox(width: 10),
              _SizeChip(
                label: '12',
                sublabel: 'Epic',
                selected: _roomSize == 'TWELVE',
                onTap: () => setState(() => _roomSize = 'TWELVE'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Developer Mode toggle ─────────────────────────────────────────
          if (kDebugMode) ...[
            GestureDetector(
              onTap: () => setState(() => _devMode = !_devMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _devMode
                      ? const Color(0xFFF59E0B).withOpacity(0.08)
                      : _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _devMode
                        ? const Color(0xFFF59E0B).withOpacity(0.4)
                        : _border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _devMode
                            ? const Color(0xFFF59E0B).withOpacity(0.15)
                            : _border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bug_report_outlined,
                        size: 18,
                        color: _devMode
                            ? const Color(0xFFF59E0B)
                            : _textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Developer Mode',
                                style: TextStyle(
                                  color: _devMode
                                      ? const Color(0xFFF59E0B)
                                      : _textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_devMode) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '⚡ DEV',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fill empty slots with bots. All roles visible.',
                            style: TextStyle(
                              color: _devMode
                                  ? const Color(0xFFF59E0B).withOpacity(0.7)
                                  : _textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _devMode,
                      onChanged: (v) => setState(() => _devMode = v),
                      activeColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ),
            if (_devMode) ...[
              const SizedBox(height: 10),
              _buildDevHostRoleDropdown(),
            ],
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Create Room',
            icon: Icons.add,
            loading: _loading,
            onTap: _createRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.login_rounded, color: _gold, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Room',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Enter a 6-character room code',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _JoinCodeButton(onJoin: _joinRoom, loading: _loading),
        ],
      ),
    );
  }

  Widget _buildRulesHint() {
    // (emoji, displayName, tagline, roleImagePath, accentColor)
    final roles = [
      ('🔪', 'Mafia',   'Kills at night',        'assets/images/mafia/role_mafia.png',          const Color(0xFFEF4444)),
      ('🩺', 'Doctor',  'Saves one player',       'assets/images/mafia/role_doctor.png',         const Color(0xFF22C55E)),
      ('🔎', 'Cop',     'Investigates a player',  'assets/images/mafia/role_cop.png',            const Color(0xFF3B82F6)),
      ('👤', 'Citizen', 'Vote out mafia',          'assets/images/mafia/role_citizen.png',        const Color(0xFF9CA3AF)),
      ('🩹', 'Nurse',   'Assists the Doctor',     'assets/images/mafia/role_nurse.png',          const Color(0xFF34D399)),
      ('🎯', 'Hitman',  'Silent assassin',        'assets/images/mafia/role_hitman.png',         const Color(0xFFF97316)),
      ('💰', 'Bounty Hunter', 'Tracks targets',   'assets/images/mafia/role_bounty_hunter.png',  const Color(0xFFF59E0B)),
      ('🔮', 'Prophet', 'Sees alignments',        'assets/images/mafia/role_prophet.png',        const Color(0xFFA855F7)),
      ('📡', 'Reporter','Broadcasts identity',   'assets/images/mafia/role_reporter.png',       const Color(0xFF06B6D4)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROLES — tap to preview',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((r) {
            final emoji = r.$1;
            final name  = r.$2;
            final tag   = r.$3;
            final img   = r.$4;
            final color = r.$5;
            return GestureDetector(
              onTap: () => _showRoleCard(context, name, img, color),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          tag,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.open_in_new_rounded, size: 12, color: color.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showRoleCard(BuildContext context, String name, String imagePath, Color accent) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Icon(Icons.close_rounded, color: accent.withValues(alpha: 0.6), size: 20),
                  ),
                ],
              ),
            ),
            // Role image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 220,
                  color: const Color(0xFF111827),
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ░░░░░░░░░░░░░░░░░░░░░░  PHASE B — WAITING ROOM  ░░░░░░░░░░░░░░░░░░░░░░░░░

  Widget _buildWaitingRoom() {
    return Column(
      children: [
        _buildRoomHeader(),
        // ── Compact player strip ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                _buildError(_error!),
                const SizedBox(height: 8),
              ],
              _buildPlayerCount(),
              const SizedBox(height: 8),
              _buildCompactPlayerStrip(),
            ],
          ),
        ),
        // ── Chat takes all remaining space ───────────────────────────────
        Expanded(
          child: _LobbyChatWidget(roomCode: _roomCode ?? ''),
        ),
        // ── Action buttons pinned at bottom ──────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isHost) ...[
                  _buildStartButton(),
                  const SizedBox(height: 4),
                ] else ...[
                  _buildWaitingHint(),
                  const SizedBox(height: 4),
                ],
                _buildLeaveButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Horizontally scrollable row of player avatars – compact for the split UI.
  Widget _buildCompactPlayerStrip() {
    if (_players.isEmpty) {
      return const Text(
        'No players yet — share the room code!',
        style: TextStyle(color: _textSecondary, fontSize: 12),
      );
    }
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _maxPlayers,
        itemBuilder: (_, i) {
          final filled = i < _players.length;
          final p = filled ? _players[i] : null;
          final isMe = p?.userId == _myUserId;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: filled
                  ? LinearGradient(
                      colors: isMe
                          ? [const Color(0xFF4C1D95), _accentGlow]
                          : [const Color(0xFF1E293B), const Color(0xFF334155)],
                    )
                  : null,
              color: filled ? null : _bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: filled ? _accent.withValues(alpha: 0.4) : _border,
              ),
            ),
            child: Center(
              child: filled
                  ? Text(
                      p!.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: _border,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _leaveRoom,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Waiting Room',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_isHost)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: _accentGlow,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              if (_devMode)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    '⚡ DEV',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Room Code display
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _roomCode ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room code copied!'),
                  duration: Duration(seconds: 1),
                  backgroundColor: _accent,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1040), Color(0xFF2D1A5E)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROOM CODE',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _roomCode ?? '------',
                        style: const TextStyle(
                          color: _accentGlow,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.copy_rounded,
                    color: _textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCount() {
    return Row(
      children: [
        const Icon(Icons.people_outline, color: _textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(
          'Players  ',
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        Text(
          '${_players.length}',
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          ' / $_maxPlayers',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        const Spacer(),
        if (_roomFull)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FULL',
              style: TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildStartButton() {
    // In dev mode: can always start (bots will fill remaining slots)
    // Normal mode: need a full room
    final canStart = (_roomFull || _devMode) && !_loading;
    final roomMax = _roomSize == 'FIVE'
        ? 5
        : _roomSize == 'EIGHT'
        ? 8
        : 12;
    final label = _devMode
        ? (_roomFull
              ? 'Start Game'
              : 'Start with Bots (${_players.length}/$roomMax)')
        : (_roomFull ? 'Start Game' : 'Waiting for players...');
    return _PrimaryButton(
      label: label,
      icon: Icons.play_arrow_rounded,
      loading: _loading,
      onTap: canStart ? _startGame : null,
    );
  }

  Widget _buildWaitingHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulse,
            child: const Icon(
              Icons.hourglass_bottom_rounded,
              color: _textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Waiting for the host to start the game...',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevHostRoleDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GameRole?>(
          value: _devHostRole,
          dropdownColor: _card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFF59E0B),
          ),
          isExpanded: true,
          hint: const Text(
            'Host Role (Random)',
            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 14),
          ),
          items: [
            const DropdownMenuItem<GameRole?>(
              value: null,
              child: Text(
                'Host Role (Random)',
                style: TextStyle(color: Color(0xFFF59E0B)),
              ),
            ),
            ...GameRole.values.map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text(
                  r.name,
                  style: const TextStyle(color: _textPrimary),
                ),
              ),
            ),
          ],
          onChanged: (val) {
            setState(() => _devHostRole = val);
          },
        ),
      ),
    );
  }

  Widget _buildLeaveButton() {
    return TextButton(
      onPressed: _leaveRoom,
      style: TextButton.styleFrom(
        foregroundColor: _red,
        minimumSize: const Size.fromHeight(44),
      ),
      child: const Text(
        'Leave Room',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildError(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: const TextStyle(color: _red, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, color: _red, size: 16),
          ),
        ],
      ),
    );
  }
}

// ─── LOBBY CHAT WIDGET ────────────────────────────────────────────────────────

/// Pre-game lobby chat — works without GameController.
/// Uses [PusherService] for receiving and [GameApi] for sending, both of
/// which are already connected when the waiting room is active.
class _LobbyChatWidget extends StatefulWidget {
  final String roomCode;
  const _LobbyChatWidget({required this.roomCode});

  @override
  State<_LobbyChatWidget> createState() => _LobbyChatWidgetState();
}

class _LobbyChatWidgetState extends State<_LobbyChatWidget> {
  final List<ChatMessage> _msgs = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sub = PusherService.instance.onChatMessage.listen(_onMsg);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onMsg(Map<String, dynamic> data) {
    if (!mounted) return;
    // Show only global / lobby channel messages in the waiting room
    final ch = data['channel'] as String? ?? 'global';
    if (ch != 'global' && ch != 'lobby') return;
    setState(() => _msgs.insert(0, ChatMessage.fromJson(data)));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || widget.roomCode.isEmpty) return;
    setState(() => _sending = true);
    try {
      await GameApi.instance.sendChat(widget.roomCode, text);
      _input.clear();
    } catch (_) {
      // Fail silently in lobby
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header strip ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          color: const Color(0xFF0D0B1E),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: _accentGlow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '💬  LOBBY CHAT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _accentGlow,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${_msgs.length} messages',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        // ── Messages ────────────────────────────────────────────────────
        Expanded(
          child: _msgs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💬', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text(
                        'No messages yet.\nSay hi while you wait!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) {
                    final m = _msgs[i];
                    if (m.isSystem) {
                      return _LobbySystemBubble(msg: m);
                    }
                    return _LobbyMsgBubble(msg: m);
                  },
                ),
        ),
        // ── Input ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: _bg,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                  ),
                  child: TextField(
                    controller: _input,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Chat while you wait...',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _sending ? _border : _accent,
                    shape: BoxShape.circle,
                    boxShadow: _sending
                        ? null
                        : [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LobbyMsgBubble extends StatelessWidget {
  final ChatMessage msg;
  const _LobbyMsgBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final istTime = msg.timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));
    final h = istTime.hour.toString().padLeft(2, '0');
    final m = istTime.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _accent.withValues(alpha: 0.2),
            child: Text(
              msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _accentGlow,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _accentGlow,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    msg.message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: _textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '$h:$m IST',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbySystemBubble extends StatelessWidget {
  final ChatMessage msg;
  const _LobbySystemBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Text(
            msg.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SUBWIDGETS ───────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _SizeChip({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.15) : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _accentGlow : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? _accentGlow : _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  color: selected
                      ? _accentGlow.withValues(alpha: 0.7)
                      : _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF5B21B6), _accentGlow],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : _border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? Colors.white : _textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Shows a code input bottom sheet when tapped.
class _JoinCodeButton extends StatelessWidget {
  final void Function(String) onJoin;
  final bool loading;
  const _JoinCodeButton({required this.onJoin, required this.loading});

  @override
  Widget build(BuildContext context) {
    return _PrimaryButton(
      label: 'Enter Room Code',
      icon: Icons.keyboard,
      loading: loading,
      onTap: () => _showCodeSheet(context),
    );
  }

  void _showCodeSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Room Code',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask your host for the 6-character code',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                  color: _accentGlow,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: const TextStyle(
                    color: _border,
                    fontSize: 26,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: _card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _accentGlow),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  final code = controller.text.trim().toUpperCase();
                  if (code.length == 6) {
                    Navigator.pop(ctx);
                    onJoin(code);
                  }
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), _accentGlow],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Join Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── ENTRY TAB CHIP ──────────────────────────────────────────────────────────

class _EntryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EntryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accent.withOpacity(0.15) : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent.withOpacity(0.5) : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? _accentGlow : _textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? _accentGlow : _textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
