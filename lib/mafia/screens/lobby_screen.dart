import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/game_controller.dart';
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

  StreamSubscription<Map<String, dynamic>>? _joinSub;
  StreamSubscription<Map<String, dynamic>>? _startSub;

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
    _startSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Pusher lobby subscriptions ─────────────────────────────────────────────

  void _subscribeLobbyEvents() {
    _joinSub?.cancel();
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
              userId: userId,
              name: name,
              status: PlayerStatus.ALIVE,
            ),
          ];
        });
      }
    });

    // game-started → GameController takes over and navigates to role screen
    _startSub = _pusher.onGameStarted.listen((data) async {
      if (!mounted || _roomCode == null || _myUserId == null) return;
      final gc = context.read<GameController>();
      // init() fetches room state, connects Pusher fully, then routes to /mafia/role
      await gc.init(_roomCode!, _myUserId!);
    });
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
      await _api.startGame(_roomCode!);
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

  void _leaveRoom() {
    _joinSub?.cancel();
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
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _inRoom ? _buildWaitingRoom() : _buildEntry(),
      ),
    );
  }

  // ░░░░░░░░░░░░░░░░░░░░░░░░  PHASE A — ENTRY  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

  Widget _buildEntry() {
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
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _textSecondary, size: 16),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), _accentGlow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: const Center(
              child: Text('🎭', style: TextStyle(fontSize: 34)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nimbus Mafia',
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
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_circle_outline,
                    color: _accentGlow, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Room',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Host a new game for your group',
                        style:
                            TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Room size',
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
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
                  color: _gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.login_rounded, color: _gold, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Join Room',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Enter a 6-character room code',
                        style:
                            TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _JoinCodeButton(
            onJoin: _joinRoom,
            loading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesHint() {
    final roles = [
      ('🔪', 'Mafia', 'Kills at night'),
      ('🩺', 'Doctor', 'Saves one player'),
      ('🔎', 'Cop', 'Investigates a player'),
      ('👤', 'Citizen', 'Vote out mafia'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ROLES',
            style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles
              .map((r) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.$1,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.$2,
                                style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text(r.$3,
                                style: const TextStyle(
                                    color: _textSecondary, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ░░░░░░░░░░░░░░░░░░░░░░  PHASE B — WAITING ROOM  ░░░░░░░░░░░░░░░░░░░░░░░░░

  Widget _buildWaitingRoom() {
    return Column(
      children: [
        _buildRoomHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                if (_error != null) ...[
                  _buildError(_error!),
                  const SizedBox(height: 12),
                ],
                _buildPlayerCount(),
                const SizedBox(height: 16),
                _buildPlayerList(),
                const SizedBox(height: 24),
                if (_isHost) _buildStartButton(),
                if (!_isHost) _buildWaitingHint(),
                const SizedBox(height: 16),
                _buildLeaveButton(),
              ],
            ),
          ),
        ),
      ],
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
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _textSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Waiting Room',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_isHost)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('HOST',
                      style: TextStyle(
                          color: _accentGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1040), Color(0xFF2D1A5E)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROOM CODE',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
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
                  const Icon(Icons.copy_rounded,
                      color: _textSecondary, size: 20),
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
              fontWeight: FontWeight.w800),
        ),
        Text(
          ' / $_maxPlayers',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        const Spacer(),
        if (_roomFull)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('FULL',
                style: TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ),
      ],
    );
  }

  Widget _buildPlayerList() {
    if (_players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Text('Waiting for players to join...',
              style: TextStyle(color: _textSecondary, fontSize: 14)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _players.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _border),
        itemBuilder: (_, i) {
          final p = _players[i];
          final isMe = p.userId == _myUserId;
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMe
                          ? [const Color(0xFF4C1D95), _accentGlow]
                          : [
                              const Color(0xFF1E293B),
                              const Color(0xFF334155)
                            ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      p.name.isNotEmpty
                          ? p.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isMe ? '${p.name} (You)' : p.name,
                    style: TextStyle(
                      color: isMe ? _accentGlow : _textPrimary,
                      fontSize: 14,
                      fontWeight: isMe
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (i == 0)
                  const Text('HOST',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartButton() {
    final canStart = _roomFull && !_loading;
    return _PrimaryButton(
      label: _roomFull ? 'Start Game' : 'Waiting for players...',
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
            child: const Icon(Icons.hourglass_bottom_rounded,
                color: _textSecondary, size: 18),
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

  Widget _buildLeaveButton() {
    return TextButton(
      onPressed: _leaveRoom,
      style: TextButton.styleFrom(
        foregroundColor: _red,
        minimumSize: const Size.fromHeight(44),
      ),
      child: const Text('Leave Room',
          style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildError(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _red, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style:
                      const TextStyle(color: _red, fontSize: 13))),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, color: _red, size: 16),
          ),
        ],
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
            color: selected ? _accent.withOpacity(0.15) : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _accentGlow : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                    color: selected ? _accentGlow : _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 2),
              Text(sublabel,
                  style: TextStyle(
                    color: selected ? _accentGlow.withOpacity(0.7) : _textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  )),
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
                      color: _accent.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
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
              const Text('Enter Room Code',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Ask your host for the 6-character code',
                  style:
                      TextStyle(color: _textSecondary, fontSize: 13)),
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
                      color: _border, fontSize: 26, letterSpacing: 8),
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
                      horizontal: 20, vertical: 18),
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
                          color: _accent.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                    child: Text('Join Room',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
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
