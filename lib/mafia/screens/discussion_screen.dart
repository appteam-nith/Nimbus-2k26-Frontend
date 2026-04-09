import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../controller/game_controller.dart';
import '../models/death_event.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../widgets/linear_phase_timer.dart';
import '../widgets/chat_widget.dart';
import '../widgets/dev_role_board.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen>
    with SingleTickerProviderStateMixin {
  // Morning reveal overlay state
  bool _showMorningReveal = false;
  bool _showReporterOverlay = false;
  List<DeathEvent> _localDeaths = [];
  Map<String, dynamic>? _localReporterData;

  late AnimationController _overlayFade;
  Timer? _autoDismissTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playAudio();
    _overlayFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Show overlays after the frame renders (data already on controller)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverlays());
  }

  Future<void> _playAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(
      AssetSource('audio/piano_music-calm-morning-125568.mp3.mpeg'),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _autoDismissTimer?.cancel();
    _overlayFade.dispose();
    super.dispose();
  }

  void _checkOverlays() {
    if (!mounted) return;
    final gc = context.read<GameController>();

    // Always show the morning overlay when entering DISCUSSION. This
    // covers both peaceful mornings and nights with deaths. If a
    // reporter broadcast is present, chain it after the morning overlay.
    setState(() {
      _localDeaths = gc.nightDeaths;
      _showMorningReveal = true;
    });
    _overlayFade.forward();

    // Keep the morning card slightly shorter for peaceful nights.
    final int displaySeconds =
        (gc.nightDeaths.isNotEmpty || gc.pendingBroadcast != null) ? 5 : 3;

    _autoDismissTimer = Timer(Duration(seconds: displaySeconds), () {
      if (!mounted) return;
      if (gc.pendingBroadcast != null) {
        _dismissMorning(thenShowReporter: true);
      } else {
        _dismissMorning(thenShowReporter: false);
      }
    });
  }

  void _dismissMorning({required bool thenShowReporter}) {
    _overlayFade.reverse().then((_) {
      if (!mounted) return;
      setState(() => _showMorningReveal = false);
      if (thenShowReporter && mounted) {
        final gc = context.read<GameController>();
        if (gc.pendingBroadcast != null) {
          _showReporterFromBroadcast(gc.pendingBroadcast!);
        }
      }
    });
  }

  void _showReporterFromBroadcast(ReporterBroadcast broadcast) {
    // Convert ReporterBroadcast to Map for the overlay widget
    _showReporter({
      'exposedRole': broadcast.role.name,
      'targetUserId': '',
      'playerName': broadcast.playerName,
    });
  }

  void _showReporter(Map<String, dynamic> data) {
    setState(() {
      _localReporterData = data;
      _showReporterOverlay = true;
    });
    _overlayFade.forward(from: 0);
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _overlayFade.reverse().then((_) {
        if (mounted) setState(() => _showReporterOverlay = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final myRole = game.myRole;
    final me = game.players.firstWhere(
      (p) => p.userId == game.myUserId,
      orElse: () => const PlayerModel(
        playerId: '',
        userId: '',
        name: '',
        status: PlayerStatus.ELIMINATED,
      ),
    );
    final isAlive = me.isAlive;

    // Determine if player can access team chat
    final bool hasMafiaChat =
        myRole?.name == 'MAFIA' || myRole?.name == 'MAFIA_HELPER';
    // (Hitman gets mafia chat only after meeting — backend enforces, show tab anyway)
    final bool hasHitmanMafiaChat = myRole?.name == 'HITMAN';
    final bool hasDocChat =
        (myRole?.name == 'DOCTOR' || myRole?.name == 'NURSE') &&
        game.roomSize == 'TWELVE' &&
        game.nurseMet;

    final aliveCount = game.players.where((p) => p.isAlive).length;
    final deltaSeconds = game.dayTimeDeltaSeconds > 0
        ? game.dayTimeDeltaSeconds
        : (aliveCount > 0 ? (120 / aliveCount).round() : 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D121B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'DISCUSSION',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.green,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────────
          Column(
            children: [
              // Compact linear phase timer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: LinearPhaseTimer(
                  endTime:
                      game.phaseEndsAt ??
                      DateTime.now().add(
                        Duration(
                          seconds: game.timeRemaining > 0
                              ? game.timeRemaining
                              : 120,
                        ),
                      ),
                  height: 6,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              // ── Day timer adjustment (compact) ───────────────────────────────
              if (game.status == GameStatus.DISCUSSION && isAlive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CompactDayAdjustButton(
                        symbol: '+',
                        active: game.myDayTimeAdjustment == 1,
                        color: const Color(0xFF22C55E),
                        disabled:
                            game.isAdjustingDayTime ||
                            game.myDayTimeAdjustment != 0,
                        onTap: () {
                          game.adjustDiscussionTime(1);
                        },
                      ),
                      const SizedBox(width: 12),
                      _CompactDayAdjustButton(
                        symbol: '−',
                        active: game.myDayTimeAdjustment == -1,
                        color: const Color(0xFFEF4444),
                        disabled:
                            game.isAdjustingDayTime ||
                            game.myDayTimeAdjustment != 0,
                        onTap: () {
                          game.adjustDiscussionTime(-1);
                        },
                      ),
                    ],
                  ),
                ),
              if (hasMafiaChat || hasDocChat || hasHitmanMafiaChat)
                _TeamChatBanner(
                  role: myRole?.name ?? '',
                  hasMafiaChat: hasMafiaChat || hasHitmanMafiaChat,
                  hasDocChat: hasDocChat,
                ),
              Expanded(child: const ChatWidget()),
            ],
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (game.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // ── Morning Death Reveal Overlay ──────────────────────────────────
          if (_showMorningReveal)
            FadeTransition(
              opacity: _overlayFade,
              child: _MorningRevealOverlay(
                deaths: _localDeaths,
                players: game.players,
                onDismiss: () {
                  _autoDismissTimer?.cancel();
                  final gc = context.read<GameController>();
                  if (gc.pendingBroadcast != null) {
                    _dismissMorning(thenShowReporter: true);
                  } else {
                    _dismissMorning(thenShowReporter: false);
                  }
                },
              ),
            ),

          // ── Reporter BREAKING NEWS Overlay ────────────────────────────────
          if (_showReporterOverlay && _localReporterData != null)
            FadeTransition(
              opacity: _overlayFade,
              child: _ReporterOverlay(
                data: _localReporterData!,
                onDismiss: () {
                  _autoDismissTimer?.cancel();
                  _overlayFade.reverse().then((_) {
                    if (mounted) setState(() => _showReporterOverlay = false);
                  });
                },
              ),
            ),

          // ── Dev Mode Role Board overlay ────────────────────────────────────
          if (game.devMode)
            DevRoleBoard(players: game.players, myUserId: game.myUserId),
        ],
      ),
    );
  }
}

// ─── TEAM CHAT BANNER ────────────────────────────────────────────────────────

class _DayAdjustButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool disabled;
  final Color color;
  final VoidCallback onTap;

  const _DayAdjustButton({
    required this.label,
    required this.active,
    required this.disabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.22)
              : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? color : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── COMPACT DAY ADJUST BUTTON ────────────────────────────────────────────────

class _CompactDayAdjustButton extends StatelessWidget {
  final String symbol;
  final bool active;
  final bool disabled;
  final Color color;
  final VoidCallback onTap;

  const _CompactDayAdjustButton({
    required this.symbol,
    required this.active,
    required this.disabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.22)
              : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: active ? color : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamChatBanner extends StatelessWidget {
  final String role;
  final bool hasMafiaChat;
  final bool hasDocChat;

  const _TeamChatBanner({
    required this.role,
    required this.hasMafiaChat,
    required this.hasDocChat,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasMafiaChat
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
    final label = hasMafiaChat
        ? '🔫 You also have access to the Mafia private chat during NIGHT'
        : '💉 You also have access to the Doctor–Nurse private chat during NIGHT';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

// ─── MORNING REVEAL OVERLAY ──────────────────────────────────────────────────

class _MorningRevealOverlay extends StatelessWidget {
  final List<DeathEvent> deaths;
  final List<dynamic> players; // List<PlayerModel>
  final VoidCallback onDismiss;

  const _MorningRevealOverlay({
    required this.deaths,
    required this.players,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: const Color(0xFF0D121B).withValues(alpha: 0.96),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                '🌅  MORNING REPORT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deaths.isEmpty
                    ? 'No one died tonight'
                    : deaths.length == 1
                    ? 'One soul was lost in the night'
                    : '${deaths.length} souls were lost in the night',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (deaths.isEmpty)
                const Text('😴', style: TextStyle(fontSize: 64))
              else
                ...deaths.map((d) => _DeathCard(death: d, players: players)),
              const SizedBox(height: 40),
              Text(
                'Tap to continue',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeathCard extends StatelessWidget {
  final DeathEvent death;
  final List<dynamic> players;

  const _DeathCard({required this.death, required this.players});

  @override
  Widget build(BuildContext context) {
    // Use player name directly from DeathEvent
    final name = death.player.name;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2333),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                death.cause.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  death.cause.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
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

// ─── REPORTER OVERLAY ────────────────────────────────────────────────────────

class _ReporterOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const _ReporterOverlay({required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final exposedRole = data['exposedRole'] as String? ?? '???';
    final targetUserId = data['targetUserId'] as String? ?? '';

    // Try to get the name from the game controller's player list
    String targetName = 'Someone';
    try {
      final gc = context.read<GameController>();
      final p = gc.players.firstWhere((p) => p.userId == targetUserId);
      targetName = p.name;
    } catch (_) {}

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: const Color(0xFF0D121B).withValues(alpha: 0.97),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Breaking news badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD946EF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '📰  BREAKING NEWS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  targetName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'has been identified as',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD946EF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD946EF).withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD946EF).withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    exposedRole.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD946EF),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Tap to dismiss',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
