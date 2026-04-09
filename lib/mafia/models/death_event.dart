import 'player_model.dart';

/// A single death that occurred during the night or day cycle.
/// Multiple [DeathEvent]s are shown as individual cards on the morning reveal.
class DeathEvent {
  final PlayerModel player;
  final DeathCause cause;

  const DeathEvent({required this.player, required this.cause});

  factory DeathEvent.fromJson(
    Map<String, dynamic> json,
    List<PlayerModel> allPlayers,
  ) {
    final playerId = json['playerId'] as String?;
    final userId = json['userId'] as String?;
    final player = allPlayers.firstWhere(
      (p) =>
          (userId != null && p.userId == userId) ||
          (playerId != null && p.playerId == playerId),
      orElse: () => PlayerModel(
        playerId: playerId ?? userId ?? '',
        userId: userId ?? playerId ?? '',
        name: json['name'] as String? ?? '?',
        status: PlayerStatus.ELIMINATED,
        role: json['role'] != null
            ? GameRole.values.firstWhere(
                (r) => r.name == json['role'],
                orElse: () => GameRole.CITIZEN,
              )
            : null,
      ),
    );
    final causeRaw =
        (json['cause'] as String?) ?? (json['killedBy'] as String?);
    final cause = _parseCause(causeRaw);
    return DeathEvent(player: player, cause: cause);
  }

  static DeathCause _parseCause(String? raw) {
    switch (raw) {
      case 'VOTE_ELIMINATION':
      case 'VOTE':
        return DeathCause.VOTE_ELIMINATION;
      case 'HITMAN_KILL':
      case 'HITMAN':
        return DeathCause.HITMAN_KILL;
      case 'BOUNTY_KILL':
      case 'BOUNTY_HUNTER':
        return DeathCause.BOUNTY_KILL;
      case 'MAFIA_KILL':
      case 'MAFIA':
      default:
        return DeathCause.MAFIA_KILL;
    }
  }
}

enum DeathCause {
  MAFIA_KILL,
  HITMAN_KILL,
  BOUNTY_KILL,
  VOTE_ELIMINATION;

  String get label {
    switch (this) {
      case DeathCause.MAFIA_KILL:
        return 'Killed by the Mafia';
      case DeathCause.HITMAN_KILL:
        return 'Struck by the Hitman';
      case DeathCause.BOUNTY_KILL:
        return 'Hunted by the Bounty Hunter';
      case DeathCause.VOTE_ELIMINATION:
        return 'Eliminated by town vote';
    }
  }

  String get emoji {
    switch (this) {
      case DeathCause.MAFIA_KILL:
        return '🔫';
      case DeathCause.HITMAN_KILL:
        return '🗡️';
      case DeathCause.BOUNTY_KILL:
        return '🎯';
      case DeathCause.VOTE_ELIMINATION:
        return '⚖️';
    }
  }
}
