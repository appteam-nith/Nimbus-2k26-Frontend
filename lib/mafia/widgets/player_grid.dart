import 'package:flutter/material.dart';
import '../models/player_model.dart';

/// Grid of player avatar tiles.
///
/// [selectedUserId] — the player the current user has tapped (for voting).
/// [onTap]          — called with userId when a tile is tapped (optional).
/// [showRoles]      — if true, shows role badge below name (Game Over screen).
class PlayerGrid extends StatelessWidget {
  final List<PlayerModel> players;
  final String? selectedUserId;
  final String? myUserId;
  final ValueChanged<String>? onTap;
  final bool showRoles;

  const PlayerGrid({
    super.key,
    required this.players,
    this.selectedUserId,
    this.myUserId,
    this.onTap,
    this.showRoles = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isSelected = player.userId == selectedUserId;
        final isMe = player.userId == myUserId;
        final isEliminated = player.isEliminated;

        return GestureDetector(
          onTap: (onTap != null && !isEliminated && !isMe)
              ? () => onTap!(player.userId)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF135BEC).withValues(alpha: 0.15)
                  : const Color(0xFF1C2333),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF135BEC)
                    : isMe
                        ? const Color(0xFF135BEC).withValues(alpha: 0.4)
                        : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isEliminated
                            ? const Color(0xFF374151)
                            : _avatarColor(player.userId),
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isEliminated
                                ? const Color(0xFF6B7280)
                                : Colors.white,
                          ),
                        ),
                      ),
                      if (isEliminated)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    isMe ? '${player.name} (You)' : player.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isEliminated
                          ? const Color(0xFF6B7280)
                          : Colors.white,
                    ),
                  ),
                  if (showRoles && player.role != null) ...[
                    const SizedBox(height: 4),
                    _RoleBadge(role: player.role!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Deterministic color from userId string
  Color _avatarColor(String userId) {
    final colors = [
      const Color(0xFF3B5BDB),
      const Color(0xFF0CA678),
      const Color(0xFFE64980),
      const Color(0xFFE67700),
      const Color(0xFF7048E8),
      const Color(0xFF1098AD),
    ];
    final hash = userId.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}

// ─── ROLE BADGE ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final GameRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _roleColor(role).withValues(alpha: 0.4)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: _roleColor(role),
        ),
      ),
    );
  }

  Color _roleColor(GameRole role) {
    switch (role) {
      case GameRole.MAFIA:
      case GameRole.MAFIA_HELPER:
      case GameRole.HITMAN:
        return const Color(0xFFEF4444);
      case GameRole.DOCTOR:
      case GameRole.NURSE:
        return const Color(0xFF22C55E);
      case GameRole.COP:
      case GameRole.REPORTER:
      case GameRole.BOUNTY_HUNTER:
        return const Color(0xFF3B82F6);
      case GameRole.CITIZEN:
      case GameRole.PROPHET:
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
