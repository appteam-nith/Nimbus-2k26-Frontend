import 'package:flutter/material.dart';
import '../models/player_model.dart';

/// Glassmorphism role reveal card.
/// Used on [RoleScreen] (large, with flip animation) and
/// on [GameOverScreen] roster (compact mode).
class RoleCard extends StatelessWidget {
  final GameRole role;
  final bool compact;

  const RoleCard({
    super.key,
    required this.role,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactCard(role: role);
    return _FullCard(role: role);
  }
}

// ─── FULL CARD  (RoleScreen) ─────────────────────────────────────────────────

class _FullCard extends StatelessWidget {
  final GameRole role;
  const _FullCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final glowColor = _glowColor(role);

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2333),
            glowColor.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withValues(alpha: 0.12),
              border: Border.all(color: glowColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                _roleEmoji(role),
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Role name
          Text(
            'You are',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            role.displayName.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: glowColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            color: glowColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            role.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          if (role.isMafia) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: const Text(
                '⚠️ Do not reveal your role.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── COMPACT CARD  (GameOver roster) ─────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  final GameRole role;
  const _CompactCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final glowColor = _glowColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: glowColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: glowColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_roleEmoji(role),
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: glowColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

Color _glowColor(GameRole role) {
  switch (role) {
    case GameRole.MAFIA:
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
      return const Color(0xFFF97316); // orange
    case GameRole.BOUNTY_HUNTER:
      return const Color(0xFFF59E0B); // amber
    case GameRole.PROPHET:
      return const Color(0xFFA855F7); // purple
    case GameRole.REPORTER:
      return const Color(0xFF06B6D4); // cyan
  }
}

String _roleEmoji(GameRole role) {
  switch (role) {
    case GameRole.MAFIA:
      return '\uD83D\uDD2B'; // 🔫
    case GameRole.DOCTOR:
      return '\uD83D\uDC89'; // 💉
    case GameRole.NURSE:
      return '\uD83E\uDE7A'; // 🩺
    case GameRole.COP:
      return '\uD83D\uDD0D'; // 🔍
    case GameRole.CITIZEN:
      return '\uD83D\uDC64'; // 👤
    case GameRole.HITMAN:
      return '\uD83D\uDDE1\uFE0F'; // 🗡️
    case GameRole.BOUNTY_HUNTER:
      return '\uD83C\uDFAF'; // 🎯
    case GameRole.PROPHET:
      return '\uD83D\uDD2E'; // 🔮
    case GameRole.REPORTER:
      return '\uD83D\uDCF0'; // 📰
  }
}
