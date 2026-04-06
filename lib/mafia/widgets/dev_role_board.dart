import 'package:flutter/material.dart';
import '../models/player_model.dart';

/// A collapsed/expanded panel that shows all player roles in Developer mode.
/// Attach it inside a Stack so it floats at the top of any game screen.
class DevRoleBoard extends StatefulWidget {
  final List<PlayerModel> players;
  final String? myUserId;

  const DevRoleBoard({
    super.key,
    required this.players,
    this.myUserId,
  });

  @override
  State<DevRoleBoard> createState() => _DevRoleBoardState();
}

class _DevRoleBoardState extends State<DevRoleBoard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expand;

  static const _devOrange = Color(0xFFF59E0B);
  static const _bg = Color(0xFF0D121B);
  static const _surface = Color(0xFF161D2B);
  static const _border = Color(0xFF263352);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Color _roleColor(GameRole? role) {
    if (role == null) return const Color(0xFF94A3B8);
    if (role.isMafia || role == GameRole.HITMAN) return const Color(0xFFEF4444);
    if (role == GameRole.DOCTOR || role == GameRole.NURSE) {
      return const Color(0xFF10B981);
    }
    if (role == GameRole.COP) return const Color(0xFF3B82F6);
    return const Color(0xFFA78BFA);
  }

  String _roleEmoji(GameRole? role) {
    switch (role) {
      case GameRole.MAFIA:
        return '🔪';
      case GameRole.HITMAN:
        return '🗡️';
      case GameRole.DOCTOR:
        return '🩺';
      case GameRole.NURSE:
        return '💊';
      case GameRole.COP:
        return '🔎';
      case GameRole.BOUNTY_HUNTER:
        return '🎯';
      case GameRole.REPORTER:
        return '📰';
      case GameRole.PROPHET:
        return '🔮';
      case GameRole.CITIZEN:
        return '👤';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Collapsed pill / DEV badge ────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _devOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _devOrange.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Text('DEV',
                      style: TextStyle(
                          color: _devOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _devOrange,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded role panel ───────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expand,
            axisAlignment: -1,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 220,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: _bg.withOpacity(0.97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _devOrange.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _devOrange.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13)),
                      border: Border(
                          bottom: BorderSide(
                              color: _devOrange.withOpacity(0.2))),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        const Text('ROLE BOARD',
                            style: TextStyle(
                                color: _devOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const Spacer(),
                        Text('${widget.players.length} players',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  // Player list
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: widget.players.map((p) {
                          final isMe = p.userId == widget.myUserId;
                          final roleColor = _roleColor(p.role);
                          final isAlive = p.isAlive;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            child: Row(
                              children: [
                                // Avatar initial
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: p.isBot
                                        ? const Color(0xFF1E293B)
                                        : isMe
                                            ? const Color(0xFF4C1D95)
                                            : _surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isAlive
                                          ? roleColor.withOpacity(0.5)
                                          : _border,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      p.isBot
                                          ? '🤖'
                                          : p.name.isNotEmpty
                                              ? p.name[0].toUpperCase()
                                              : '?',
                                      style: TextStyle(
                                          fontSize: p.isBot ? 12 : 11,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isMe ? '${p.name} (You)' : p.name,
                                    style: TextStyle(
                                      color: isAlive
                                          ? (isMe
                                              ? const Color(0xFF9D5EF5)
                                              : const Color(0xFFEEF2FF))
                                          : const Color(0xFF475569),
                                      fontSize: 11,
                                      fontWeight: isMe
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      decoration: isAlive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Role tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAlive
                                        ? roleColor.withOpacity(0.12)
                                        : const Color(0xFF1E293B),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_roleEmoji(p.role)} ${p.role?.displayName ?? '??'}',
                                    style: TextStyle(
                                      color: isAlive
                                          ? roleColor
                                          : const Color(0xFF475569),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
