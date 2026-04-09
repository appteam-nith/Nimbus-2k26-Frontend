import 'package:flutter/material.dart';
import '../models/player_model.dart';

/// Grid of player avatar tiles.
///
/// [selectedUserId] - currently selected player (for voting).
/// [onTap]          - called with userId when a tile is tapped (optional).
/// [showRoles]      - if true, shows role icon on each player's avatar.
/// [voteCounts]     - map of userId -> vote count, shown as badges during voting.
/// [vipUserId]      - Bounty Hunter's VIP, shown with a star marker.
class PlayerGrid extends StatelessWidget {
  final List<PlayerModel> players;
  final String? selectedUserId;
  final String? myUserId;
  final ValueChanged<String>? onTap;
  final bool showRoles;
  final bool allowSelfSelect;
  final Map<String, int>? voteCounts;
  final String? vipUserId;
  final Set<String>? leftPlayerIds;

  const PlayerGrid({
    super.key,
    required this.players,
    this.selectedUserId,
    this.myUserId,
    this.onTap,
    this.showRoles = false,
    this.allowSelfSelect = false,
    this.voteCounts,
    this.vipUserId,
    this.leftPlayerIds,
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
        final isVip = player.userId == vipUserId;
        final isLeft = leftPlayerIds?.contains(player.userId) ?? false;
        final voteCount = voteCounts?[player.userId] ?? 0;

        return GestureDetector(
          onTap:
              (onTap != null &&
                  !isEliminated &&
                  !isLeft &&
                  (!isMe || allowSelfSelect))
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
                    : isVip
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.7)
                    : isMe
                    ? const Color(0xFF135BEC).withValues(alpha: 0.4)
                    : Colors.transparent,
                width: isVip ? 2.5 : 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar circle with vote count + optional markers.
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: (isEliminated || isLeft)
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
                            color: (isEliminated || isLeft)
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
                      if (isLeft && !isEliminated)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: const Icon(
                            Icons.exit_to_app_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 22,
                          ),
                        ),
                      // Vote count badge (top-right)
                      if (voteCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66EF4444),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              '$voteCount',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      // VIP star marker (top-left)
                      if (isVip)
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66F59E0B),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      if (showRoles && player.role != null)
                        Positioned(
                          bottom: -6,
                          right: -6,
                          child: _RoleIconBadge(role: player.role!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMe ? '${player.name} (You)' : player.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (isEliminated || isLeft)
                          ? const Color(0xFF6B7280)
                          : Colors.white,
                    ),
                  ),
                  if (isLeft && !isEliminated)
                    Text(
                      'Left',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Deterministic color from userId string.
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

class _RoleIconBadge extends StatelessWidget {
  final GameRole role;

  const _RoleIconBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
      ),
      child: ClipOval(
        child: Image.asset(
          _iconPath(role),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.shield_rounded, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  String _iconPath(GameRole role) {
    switch (role) {
      case GameRole.MAFIA:
        return 'assets/images/mafia/role_mafia.png';
      case GameRole.HITMAN:
        return 'assets/images/mafia/role_hitman.png';
      case GameRole.CITIZEN:
        return 'assets/images/mafia/role_citizen.png';
      case GameRole.DOCTOR:
        return 'assets/images/mafia/role_doctor.png';
      case GameRole.COP:
        return 'assets/images/mafia/role_cop.png';
      case GameRole.NURSE:
        return 'assets/images/mafia/role_nurse.png';
      case GameRole.BOUNTY_HUNTER:
        return 'assets/images/mafia/role_bounty_hunter.png';
      case GameRole.PROPHET:
        return 'assets/images/mafia/role_prophet.png';
      case GameRole.REPORTER:
        return 'assets/images/mafia/role_reporter.png';
    }
  }
}
