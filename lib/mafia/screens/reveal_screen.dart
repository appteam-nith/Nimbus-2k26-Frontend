import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/death_event.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../widgets/linear_phase_timer.dart';

/// Morning Reveal Screen — shown after NIGHT phase ends.
///
/// Supports 0–N deaths in a staggered card carousel:
///   • Hitman + Mafia kills → multiple cards
///   • No deaths → peaceful morning card
///
/// Each card shows: player avatar → role reveal → cause of death badge.
/// Cards stagger in one by one with a blur-unmasking animation.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with TickerProviderStateMixin {
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _blurAnims = [];
  final List<Animation<double>> _scaleAnims = [];
  final List<Animation<double>> _fadeAnims = [];
  final List<Animation<Offset>> _slideAnims = [];
  int _lastDeathCount = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gc = context.read<GameController>();
    final count = gc.morningDeaths.length;
    if (count != _lastDeathCount) {
      _lastDeathCount = count;
      _buildAnimations(count);
    }
  }

  void _buildAnimations(int count) {
    // Dispose old controllers
    for (final c in _cardControllers) {
      c.dispose();
    }
    _cardControllers.clear();
    _blurAnims.clear();
    _scaleAnims.clear();
    _fadeAnims.clear();
    _slideAnims.clear();

    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      _cardControllers.add(ctrl);

      _blurAnims.add(
        Tween<double>(
          begin: 18,
          end: 0,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)),
      );
      _scaleAnims.add(
        Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)),
      );
      _fadeAnims.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: ctrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
          ),
        ),
      );
      _slideAnims.add(
        Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)),
      );

      // Stagger start
      Future.delayed(Duration(milliseconds: 300 + i * 500), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final deaths = gc.morningDeaths;
    final phaseEndsAt = gc.status == GameStatus.REVEAL && gc.timeRemaining > 0
        ? DateTime.now().add(Duration(seconds: gc.timeRemaining))
        : DateTime.now().add(const Duration(seconds: 6));

    return Scaffold(
      backgroundColor: const Color(0xFF0D121B),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ── Header ─────────────────────────────────────────────────────────
            Text(
              'R O U N D   ${gc.round}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                letterSpacing: 3,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              deaths.isEmpty
                  ? 'NO ELIMINATION'
                  : deaths.length == 1
                  ? 'ONE FALLEN'
                  : '${deaths.length} HAVE FALLEN',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (deaths.isNotEmpty)
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/mafia/vote_out.png'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              deaths.isEmpty
                  ? 'The town failed to reach a conviction.'
                  : 'The town has spoken.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white.withOpacity(0.45),
              ),
            ),

            const SizedBox(height: 28),

            // ── Death cards / peaceful state ────────────────────────────────────
            Expanded(
              child: deaths.isEmpty
                  ? _PeacefulMorning()
                  : _DeathCardList(
                      deaths: deaths,
                      cardControllers: _cardControllers,
                      blurAnims: _blurAnims,
                      scaleAnims: _scaleAnims,
                      fadeAnims: _fadeAnims,
                      slideAnims: _slideAnims,
                    ),
            ),

            // ── Countdown ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                children: [
                  LinearPhaseTimer(
                    endTime: phaseEndsAt,
                    height: 6,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Night begins soon',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PEACEFUL MORNING ─────────────────────────────────────────────────────────

class _PeacefulMorning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('NO VOTE', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 20),
          Text(
            'No one was voted out today.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Night will begin shortly.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SCROLLABLE DEATH CARD LIST ───────────────────────────────────────────────

class _DeathCardList extends StatelessWidget {
  final List<DeathEvent> deaths;
  final List<AnimationController> cardControllers;
  final List<Animation<double>> blurAnims;
  final List<Animation<double>> scaleAnims;
  final List<Animation<double>> fadeAnims;
  final List<Animation<Offset>> slideAnims;

  const _DeathCardList({
    required this.deaths,
    required this.cardControllers,
    required this.blurAnims,
    required this.scaleAnims,
    required this.fadeAnims,
    required this.slideAnims,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: deaths.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        if (i >= cardControllers.length) {
          // Safety: controller not yet built
          return _DeathCard(death: deaths[i], animation: null);
        }
        return AnimatedBuilder(
          animation: cardControllers[i],
          builder: (context, _) {
            return SlideTransition(
              position: slideAnims[i],
              child: Transform.scale(
                scale: scaleAnims[i].value,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: blurAnims[i].value,
                    sigmaY: blurAnims[i].value,
                  ),
                  child: _DeathCard(death: deaths[i], animation: fadeAnims[i]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── SINGLE DEATH CARD ────────────────────────────────────────────────────────

class _DeathCard extends StatelessWidget {
  final DeathEvent death;
  final Animation<double>? animation;

  const _DeathCard({required this.death, required this.animation});

  @override
  Widget build(BuildContext context) {
    final role = death.player.role;
    final causeColor = _causeColor(death.cause);

    // Only reveal roles for night kills, not for vote eliminations
    // Vote eliminations will be revealed on the NEXT morning's reveal screen
    final shouldShowRole =
        role != null && death.cause != DeathCause.VOTE_ELIMINATION;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1C2333), causeColor.withOpacity(0.08)],
        ),
        border: Border.all(color: causeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: causeColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: causeColor.withOpacity(0.5),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: causeColor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              color: const Color(0xFF0D121B),
            ),
            child: Center(
              child: Text(
                death.player.name.isNotEmpty
                    ? death.player.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  death.player.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),

                // Cause badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: causeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${death.cause.emoji}  ${death.cause.label}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: causeColor,
                    ),
                  ),
                ),

                // Role reveal — fades in (only for night kills, not vote eliminations)
                if (shouldShowRole) ...[
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: animation ?? const AlwaysStoppedAnimation(1.0),
                    child: _RoleRevealBadge(role: role),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _causeColor(DeathCause cause) {
    switch (cause) {
      case DeathCause.MAFIA_KILL:
        return const Color(0xFFEF4444);
      case DeathCause.HITMAN_KILL:
        return const Color(0xFFF97316);
      case DeathCause.BOUNTY_KILL:
        return const Color(0xFFF59E0B);
      case DeathCause.VOTE_ELIMINATION:
        return const Color(0xFF8B5CF6);
    }
  }
}

// ─── ROLE REVEAL BADGE ────────────────────────────────────────────────────────

class _RoleRevealBadge extends StatelessWidget {
  final GameRole role;
  const _RoleRevealBadge({required this.role});

  static final _roleColors = {
    GameRole.MAFIA: Color(0xFFEF4444),
    GameRole.DOCTOR: Color(0xFF22C55E),
    GameRole.NURSE: Color(0xFF34D399),
    GameRole.COP: Color(0xFF3B82F6),
    GameRole.CITIZEN: Color(0xFF9CA3AF),
    GameRole.HITMAN: Color(0xFFF97316),
    GameRole.BOUNTY_HUNTER: Color(0xFFF59E0B),
    GameRole.PROPHET: Color(0xFFA855F7),
    GameRole.REPORTER: Color(0xFF06B6D4),
  };

  static final _roleEmojis = {
    GameRole.MAFIA: '🔫',
    GameRole.DOCTOR: '💉',
    GameRole.NURSE: '🩺',
    GameRole.COP: '🔍',
    GameRole.CITIZEN: '👤',
    GameRole.HITMAN: '🗡️',
    GameRole.BOUNTY_HUNTER: '🎯',
    GameRole.PROPHET: '🔮',
    GameRole.REPORTER: '📰',
  };

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[role] ?? const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_roleEmojis[role] ?? '?', style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            'Was the ${role.displayName}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
