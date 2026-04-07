import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';

// ─── ROLE METADATA ────────────────────────────────────────────────────────────

class _RoleStat {
  final String label;
  final int level; // 1-10
  const _RoleStat(this.label, this.level);
}

class _RoleMeta {
  final String className;
  final String id;
  final String description;
  final List<_RoleStat> stats;
  final String imagePath;

  const _RoleMeta({
    required this.className,
    required this.id,
    required this.description,
    required this.stats,
    required this.imagePath,
  });
}

const _roleMeta = <GameRole, _RoleMeta>{
  GameRole.MAFIA: _RoleMeta(
    className: 'SYNDICATE',
    id: 'MF-812',
    description:
        'High-ranking underworld figure specializing in resource control and strategic intimidation.',
    stats: [
      _RoleStat('INFLUENCE', 10),
      _RoleStat('STEALTH', 6),
      _RoleStat('COMBAT', 8),
    ],
    imagePath: 'assets/images/mafia/role_mafia.png',
  ),
  GameRole.MAFIA_HELPER: _RoleMeta(
    className: 'SYNDICATE',
    id: 'MF-091',
    description:
        'Loyal enforcer operating in the shadows. Executes orders without hesitation.',
    stats: [
      _RoleStat('INFLUENCE', 6),
      _RoleStat('STEALTH', 8),
      _RoleStat('COMBAT', 9),
    ],
    imagePath: 'assets/images/mafia/role_mafia_helper.png',
  ),
  GameRole.DOCTOR: _RoleMeta(
    className: 'STRATEGIST',
    id: 'DR-092',
    description:
        'Elite field surgeon capable of neutralizing lethal threats. One targeted save per night.',
    stats: [
      _RoleStat('INTEL', 9),
      _RoleStat('SUPPORT', 10),
      _RoleStat('DEFENSE', 6),
    ],
    imagePath: 'assets/images/mafia/role_doctor.png',
  ),
  GameRole.NURSE: _RoleMeta(
    className: 'SUPPORT',
    id: 'NS-441',
    description:
        'Rapid-response trauma specialist. Capable of deploying automated stabilization fields and stimulant injectors to keep squad members at peak efficiency.',
    stats: [
      _RoleStat('DEFENSE', 5),
      _RoleStat('SUPPORT', 10),
      _RoleStat('INTEL', 6),
    ],
    imagePath: 'assets/images/mafia/role_nurse.png',
  ),
  GameRole.COP: _RoleMeta(
    className: 'ENFORCER',
    id: 'CP-532',
    description:
        'Front-line crowd control and heavy ordnance specialist. Equipped with kinetic shielding and non-lethal suppression systems to dominate close-quarters.',
    stats: [
      _RoleStat('DEFENSE', 10),
      _RoleStat('SPEED', 3),
      _RoleStat('IMPACT', 8),
    ],
    imagePath: 'assets/images/mafia/role_cop.png',
  ),
  GameRole.CITIZEN: _RoleMeta(
    className: 'CIVILIAN',
    id: 'CV-001',
    description:
        'An ordinary town resident with no special abilities. Survival depends on reading the room and making the right vote.',
    stats: [
      _RoleStat('INTUITION', 6),
      _RoleStat('SOCIAL', 8),
      _RoleStat('LUCK', 5),
    ],
    imagePath: 'assets/images/mafia/role_citizen.png',
  ),
  GameRole.HITMAN: _RoleMeta(
    className: 'INFILTRATOR',
    id: 'HM-037',
    description:
        'Silent executioner focused on precision and stealth. Expert in digital sabotage and long-range ballistics, designed to eliminate high-value assets silently.',
    stats: [
      _RoleStat('PRECISION', 10),
      _RoleStat('ARMOR', 2),
      _RoleStat('STEALTH', 9),
    ],
    imagePath: 'assets/images/mafia/role_hitman.png',
  ),
  GameRole.BOUNTY_HUNTER: _RoleMeta(
    className: 'AGGRESSOR',
    id: 'BH-082',
    description:
        'High-mobility tracker specialized in target isolation and neutralization. Equipped with thermal optics and grappling systems to maintain vertical superiority.',
    stats: [
      _RoleStat('OFFENSE', 9),
      _RoleStat('UTILITY', 4),
      _RoleStat('STEALTH', 7),
    ],
    imagePath: 'assets/images/mafia/role_bounty_hunter.png',
  ),
  GameRole.PROPHET: _RoleMeta(
    className: 'ORACLE',
    id: 'PR-019',
    description:
        'Gifted seer with the ability to divine the alignment of any player each night. Knowledge is the deadliest weapon.',
    stats: [
      _RoleStat('INSIGHT', 10),
      _RoleStat('STEALTH', 7),
      _RoleStat('COMBAT', 2),
    ],
    imagePath: 'assets/images/mafia/role_prophet.png',
  ),
  GameRole.REPORTER: _RoleMeta(
    className: 'INTEL',
    id: 'RP-205',
    description:
        'Embedded field correspondent with the power to broadcast a target\'s identity to all players. Information warfare at its finest.',
    stats: [
      _RoleStat('INTEL', 10),
      _RoleStat('SOCIAL', 8),
      _RoleStat('STEALTH', 5),
    ],
    imagePath: 'assets/images/mafia/role_reporter.png',
  ),
};

// ─── ROLE SCREEN ──────────────────────────────────────────────────────────────

/// Tactical mission briefing–style role reveal screen.
///
/// Matches the "Expanded Role Selection" design from the UI mockups:
///   • Dark military theme
///   • Circular role badge portrait
///   • CLASS / ID / STATS metadata
///   • Orange "SELECT ROLE" CTA
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _pulseController;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;
  late final Animation<double> _badgeScale;
  late final Animation<double> _pulseAnim;

  Timer? _autoNavTimer;
  int _countdown = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));

    _badgeScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _enterController, curve: Curves.easeOutBack),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _enterController.forward();
    });

    // Countdown label
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdown = (_countdown - 1).clamp(0, 30);
      });
      if (_countdown == 0) {
        t.cancel();
        _continue();
      }
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _pulseController.dispose();
    _autoNavTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _continue() {
    _countdownTimer?.cancel();
    context.read<GameController>().markRoleCardSeen();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final role = gc.myRole;

    if (role == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E17),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF5A28))),
      );
    }

    final meta = _roleMeta[role]!;
    final accentColor = _accentFor(role);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: FadeTransition(
        opacity: _enterFade,
        child: SlideTransition(
          position: _enterSlide,
          child: Column(
            children: [
              // ── TOP BANNER ─────────────────────────────────────────────────
              _TopBanner(),
              // ── SCROLLABLE CONTENT ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _Header(),
                      const SizedBox(height: 28),

                      // Badge
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_badgeScale, _pulseAnim, _pulseController]),
                        builder: (_, _) {
                          return Transform.scale(
                            scale: _enterController.value < 1.0
                                ? _badgeScale.value
                                : 1.0,
                            child: _BadgePortrait(
                              imagePath: meta.imagePath,
                              accentColor: accentColor,
                              pulseValue: _pulseAnim.value,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // Role card details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _RoleCard(
                          role: role,
                          meta: meta,
                          accentColor: accentColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SelectRoleButton(
                          countdown: _countdown,
                          onTap: _continue,
                          accentColor: accentColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(GameRole role) {
    switch (role) {
      case GameRole.MAFIA:
      case GameRole.MAFIA_HELPER:
      case GameRole.HITMAN:
        return const Color(0xFFEF4444);
      case GameRole.DOCTOR:
        return const Color(0xFF22C55E);
      case GameRole.NURSE:
        return const Color(0xFF34D399);
      case GameRole.COP:
        return const Color(0xFF3B82F6);
      case GameRole.CITIZEN:
        return const Color(0xFF9CA3AF);
      case GameRole.HITMAN:
        return const Color(0xFFF97316);
      case GameRole.BOUNTY_HUNTER:
        return const Color(0xFFF59E0B);
      case GameRole.PROPHET:
        return const Color(0xFFA855F7);
      case GameRole.REPORTER:
        return const Color(0xFF06B6D4);
    }
  }
}

// ─── TOP BANNER ───────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F1420),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5A28).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFF5A28).withOpacity(0.4), width: 1),
            ),
            child: const Text('📋', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MISSION BRIEFING: ROLE SELECTION',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5A28),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'EYES ONLY — CLASSIFIED',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEPLOYMENT PROTOCOL V4.2',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF5A28).withOpacity(0.7),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
              children: [
                TextSpan(
                    text: 'IDENTIFY YOUR\n',
                    style: TextStyle(color: Colors.white)),
                TextSpan(
                    text: 'SPECIALIZATION',
                    style: TextStyle(color: Color(0xFFFF5A28))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a tactical role for the upcoming operation. Each operative provides unique utility, strategic advantages, and specialized equipment critical to mission success.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BADGE PORTRAIT ───────────────────────────────────────────────────────────

class _BadgePortrait extends StatelessWidget {
  final String imagePath;
  final Color accentColor;
  final double pulseValue;

  const _BadgePortrait({
    required this.imagePath,
    required this.accentColor,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 200 * pulseValue,
            height: 200 * pulseValue,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.25 * pulseValue),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Badge border ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withOpacity(0.55),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Image
          ClipOval(
            child: Image.asset(
              imagePath,
              width: 172,
              height: 172,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 172,
                height: 172,
                color: const Color(0xFF1A1F2E),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ROLE CARD ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final GameRole role;
  final _RoleMeta meta;
  final Color accentColor;

  const _RoleCard({
    required this.role,
    required this.meta,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E2A3A),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Class / ID row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                // Class badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: accentColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    'CLASS: ${meta.className}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${meta.id}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // ── Role name
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Text(
              role.displayName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // ── Divider
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Divider(
                height: 1, color: Colors.white.withOpacity(0.07), thickness: 1),
          ),

          // ── Description
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Text(
              meta.description,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.6,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          // ── Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            child: Row(
              children: meta.stats
                  .map((s) => Expanded(child: _StatBox(stat: s, accent: accentColor)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STAT BOX ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final _RoleStat stat;
  final Color accent;

  const _StatBox({required this.stat, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1017),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: accent.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LVL ${stat.level.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SELECT ROLE BUTTON ───────────────────────────────────────────────────────

class _SelectRoleButton extends StatelessWidget {
  final int countdown;
  final VoidCallback onTap;
  final Color accentColor;

  const _SelectRoleButton({
    required this.countdown,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5A28), Color(0xFFE03E10)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5A28).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SELECT ROLE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.5,
              ),
            ),
            if (countdown < 30) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$countdown s',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
