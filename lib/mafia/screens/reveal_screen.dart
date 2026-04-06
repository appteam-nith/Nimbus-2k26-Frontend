import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../widgets/phase_timer.dart';


/// Reveal Screen — shown after voting when a player is eliminated.
///
/// Duration: 3 seconds (matches backend PHASE_DURATION.REVEAL = 3000ms).
/// The backend drives the next phase transition — this screen just animates.
///
/// Shows:
///   • Eliminated player name + avatar
///   • Role unmasking animation (blurred → clear + role badge)
///   • 3s countdown ring
///   • "No one was eliminated" state for tie votes
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _unmaskController;
  late Animation<double> _blurAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _unmaskController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _blurAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _unmaskController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _unmaskController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unmaskController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start unmask after brief delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _unmaskController.forward();
    });
  }

  @override
  void dispose() {
    _unmaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final eliminated = gc.revealedPlayer;
    final phaseEndsAt = gc.status == GameStatus.REVEAL && gc.timeRemaining > 0
        ? DateTime.now().add(Duration(seconds: gc.timeRemaining))
        : DateTime.now().add(const Duration(seconds: 3));

    return Scaffold(
      backgroundColor: const Color(0xFF0D121B),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase label
              Text(
                'R O U N D   ${gc.round}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                eliminated != null ? 'VOTE RESULT' : 'NO CONSENSUS',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),

              if (eliminated != null) ...[
                // Unmasking animation
                AnimatedBuilder(
                  animation: _unmaskController,
                  builder: (context, _) {
                    return Column(
                      children: [
                        // Blurred → clear avatar
                        Transform.scale(
                          scale: _scaleAnim.value,
                          child: ImageFiltered(
                            imageFilter: _buildBlur(_blurAnim.value),
                            child: _EliminatedAvatar(player: eliminated),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name appears as blur clears
                        Opacity(
                          opacity: (1.0 - (_blurAnim.value / 20)).clamp(0, 1),
                          child: Text(
                            eliminated.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Role badge fades in after unmask
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: eliminated.role != null
                              ? _RoleRevealBadge(role: eliminated.role!)
                              : Opacity(
                                  opacity: 0.4,
                                  child: const Text(
                                    'Role hidden',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                // No elimination (tie)
                const Text('🤝', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 20),
                Text(
                  'The town could not agree.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Night falls again…',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],

              const SizedBox(height: 56),

              // 3s countdown ring
              PhaseTimer(
                endTime: phaseEndsAt,
                size: 60,
                strokeWidth: 4,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Next phase soon',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ui.ImageFilter _buildBlur(double sigma) =>
      ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
}

// ─── ELIMINATED AVATAR ───────────────────────────────────────────────────────

class _EliminatedAvatar extends StatelessWidget {
  final PlayerModel player;
  const _EliminatedAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
        color: const Color(0xFF1C2333),
      ),
      child: Center(
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── ROLE REVEAL BADGE ───────────────────────────────────────────────────────

class _RoleRevealBadge extends StatelessWidget {
  final GameRole role;
  const _RoleRevealBadge({required this.role});

  static const _roleColors = {
    GameRole.MAFIA: Color(0xFFEF4444),
    GameRole.MAFIA_HELPER: Color(0xFFEF4444),
    GameRole.DOCTOR: Color(0xFF22C55E),
    GameRole.NURSE: Color(0xFF34D399),
    GameRole.COP: Color(0xFF3B82F6),
    GameRole.CITIZEN: Color(0xFF9CA3AF),
  };

  static const _roleEmojis = {
    GameRole.MAFIA: '🔫',
    GameRole.MAFIA_HELPER: '🗡️',
    GameRole.DOCTOR: '💉',
    GameRole.NURSE: '🩺',
    GameRole.COP: '🔍',
    GameRole.CITIZEN: '👤',
  };

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[role] ?? const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_roleEmojis[role] ?? '?',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'Was the ${role.displayName}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

