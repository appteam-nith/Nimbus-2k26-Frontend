import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../widgets/role_card.dart';

/// Cinematic role reveal screen.
///
/// Triggered by:
///   • Pusher `role-assigned` event (first game start)
///   • Reconnect when status == NIGHT and roleCardSeen == false
///
/// Auto-navigates to NightScreen after 6s or on tap.
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _glowController;
  late AnimationController _autoNavController;
  late Animation<double> _flipAnim;
  late Animation<double> _glowAnim;

  bool _isFlipped = false;
  bool _tapEnabled = false;

  @override
  void initState() {
    super.initState();

    // Card flip
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnim = Tween<double>(begin: 0, end: math.pi)
        .animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack));

    // Glow pulse after reveal
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // Auto-navigate timer
    _autoNavController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();
    _autoNavController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _continue();
      }
    });

    // Begin flip after short pause
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _flipController.forward().then((_) {
          setState(() {
            _isFlipped = true;
            _tapEnabled = true;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _autoNavController.dispose();
    super.dispose();
  }

  void _continue() {
    final gc = context.read<GameController>();
    gc.markRoleCardSeen();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final role = gc.myRole;

    if (role == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D121B),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D121B),
      body: GestureDetector(
        onTap: _tapEnabled ? _continue : null,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Background radial glow
            if (_isFlipped)
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (context, _) => Center(
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _roleGlow(role).withValues(alpha: 0.15 * _glowAnim.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Round label
                  Text(
                    'Round ${gc.round} — Your Role',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Flip card
                  AnimatedBuilder(
                    animation: _flipAnim,
                    builder: (context, child) {
                      final angle = _flipAnim.value;
                      final isFront = angle < math.pi / 2;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: isFront
                            ? _CardBack()
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: RoleCard(role: role),
                              ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Tap hint
                  AnimatedOpacity(
                    opacity: _tapEnabled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        Text(
                          'Tap anywhere to continue',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Auto-nav countdown bar
                        SizedBox(
                          width: 160,
                          child: AnimatedBuilder(
                            animation: _autoNavController,
                            builder: (context, _) => LinearProgressIndicator(
                              value: 1.0 - _autoNavController.value,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation(
                                  _roleGlow(role).withValues(alpha: 0.6)),
                              minHeight: 2,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
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

  Color _roleGlow(GameRole role) {
    switch (role) {
      case GameRole.MAFIA:
      case GameRole.MAFIA_HELPER:
      case GameRole.HITMAN:
        return const Color(0xFFEF4444);
      case GameRole.DOCTOR:
      case GameRole.NURSE:
        return const Color(0xFF22C55E);
      case GameRole.COP:
        return const Color(0xFF3B82F6);

      case GameRole.BOUNTY_HUNTER:
        return const Color(0xFFF59E0B);
      case GameRole.REPORTER:
        return const Color(0xFF8B5CF6);
      case GameRole.PROPHET:
        return const Color(0xFF14B8A6);
      case GameRole.CITIZEN:
        return const Color(0xFF9CA3AF);
    }
  }
}

// ─── CARD BACK (before flip) ─────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2544), Color(0xFF0D121B)],
        ),
        border: Border.all(
          color: const Color(0xFF135BEC).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌀',
                style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'NIMBUS MAFIA',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF135BEC),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
