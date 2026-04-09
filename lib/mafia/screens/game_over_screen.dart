import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../widgets/role_card.dart';

/// Game Over Screen — shown when `game-ended` Pusher event fires.
///
/// Shows:
///   • Winner banner with celebration animation
///   • Full player roster with all roles revealed
///   • Play Again + Home buttons
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _bannerController;
  late AnimationController _particleController;
  late Animation<double> _bannerScale;
  late Animation<double> _bannerFade;

  @override
  void initState() {
    super.initState();

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bannerScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.elasticOut),
    );
    _bannerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bannerController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _bannerController.forward();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final isMafiaWin = gc.winner == 'MAFIA';

    final winColor = isMafiaWin
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
    final winEmoji = isMafiaWin ? '🔫' : '✅';
    final winReason = gc.winReason;
    final winTitle = isMafiaWin ? 'Mafia Wins' : 'Citizens Win';
    final winSubtitle = isMafiaWin
        ? 'The Mafia controlled the town.'
        : 'The citizens rooted out the evil.';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          gc.leaveGame();
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D121B),
        body: Stack(
          children: [
            // Background particle burst
            _ParticleBurst(controller: _particleController, color: winColor),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── WINNER BANNER ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: FadeTransition(
                      opacity: _bannerFade,
                      child: ScaleTransition(
                        scale: _bannerScale,
                        child: _WinnerBanner(
                          emoji: winEmoji,
                          title: winTitle,
                          subtitle: winSubtitle,
                          color: winColor,
                          winReason: isMafiaWin ? null : winReason,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── PLAYER ROSTER ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'All Roles Revealed',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: gc.players.isNotEmpty
                          ? _PlayerRoster(
                              players: gc.players,
                              myUserId: gc.myUserId,
                            )
                          : Center(
                              child: Text(
                                'No player data',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                    ),
                  ),

                  // ── ACTIONS ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Play Again
                        _ActionButton(
                          label: 'Play Again',
                          icon: Icons.replay_rounded,
                          onPressed: () {
                            gc.leaveGame();
                            // Dev 2's lobby screen handles play again
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/mafia/lobby',
                              (r) => r.isFirst,
                            );
                          },
                          isPrimary: true,
                        ),
                        const SizedBox(height: 12),
                        // Home
                        _ActionButton(
                          label: 'Back to Home',
                          icon: Icons.home_rounded,
                          onPressed: () {
                            gc.leaveGame();
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          isPrimary: false,
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
}

// ─── WINNER BANNER ────────────────────────────────────────────────────────────

class _WinnerBanner extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final String? winReason;

  const _WinnerBanner({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.winReason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.18), const Color(0xFF1C2333)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          if (winReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(
                winReason == 'PROPHET_WIN'
                    ? '🔮 The Prophet\'s Foresight claimed victory'
                    : '⚔️ All Mafias Eliminated',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PLAYER ROSTER ────────────────────────────────────────────────────────────

class _PlayerRoster extends StatelessWidget {
  final List<PlayerModel> players;
  final String? myUserId;

  const _PlayerRoster({required this.players, this.myUserId});

  @override
  Widget build(BuildContext context) {
    // Sort: alive first, then eliminated; mafia last
    final sorted = [...players]
      ..sort((a, b) {
        if (a.isEliminated && !b.isEliminated) return 1;
        if (!a.isEliminated && b.isEliminated) return -1;
        return 0;
      });

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final player = sorted[i];
        final isMe = player.userId == myUserId;
        return _RosterTile(player: player, isMe: isMe);
      },
    );
  }
}

class _RosterTile extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;

  const _RosterTile({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isEliminated = player.isEliminated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2333),
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(
                color: const Color(0xFF135BEC).withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isEliminated
                ? const Color(0xFF374151)
                : const Color(0xFF135BEC).withValues(alpha: 0.3),
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isEliminated ? const Color(0xFF6B7280) : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${player.name} (You)' : player.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEliminated
                        ? const Color(0xFF6B7280)
                        : Colors.white,
                  ),
                ),
                if (isEliminated)
                  Text(
                    'Eliminated',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          // Role card (compact)
          if (player.role != null) RoleCard(role: player.role!, compact: true),
        ],
      ),
    );
  }
}

// ─── ACTION BUTTON ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135BEC),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.6),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── PARTICLE BURST ──────────────────────────────────────────────────────────

class _ParticleBurst extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _ParticleBurst({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(progress: controller.value, color: color),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  static const _count = 24;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height * 0.28;

    for (int i = 0; i < _count; i++) {
      final speed = 120.0 + (i % 4) * 40;
      final dist = speed * progress;
      final x = cx + dist * 1.6 * (i % 2 == 0 ? 1 : -1) * (i / _count);
      final y = cy + dist * (0.5 + (i % 3) * 0.3) - (80 * progress);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final radius = (4.0 + (i % 3) * 2.0) * (1.0 - progress * 0.5);

      paint.color =
          (i % 3 == 0
                  ? color
                  : i % 3 == 1
                  ? Colors.white
                  : color.withValues(alpha: 0.6))
              .withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
