/// Represents a single player death from a night resolution event.
/// Populated from the `deaths` array in the `phase-resolved` Pusher event.
class DeathEvent {
  final String playerId;  // GamePlayer.id (DB id)
  final String userId;    // GamePlayer.user_id (auth uid)
  final String killedBy;  // "MAFIA" | "HITMAN" | "BOUNTY_HUNTER"

  const DeathEvent({
    required this.playerId,
    required this.userId,
    required this.killedBy,
  });

  factory DeathEvent.fromJson(Map<String, dynamic> json) {
    return DeathEvent(
      playerId: json['playerId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      killedBy: json['killedBy'] as String? ?? 'MAFIA',
    );
  }

  String get killedByLabel {
    switch (killedBy) {
      case 'HITMAN':
        return 'Taken out by the Hitman';
      case 'BOUNTY_HUNTER':
        return 'Hunted down by the Bounty Hunter';
      case 'MAFIA':
      default:
        return 'Eliminated by the Mafia';
    }
  }

  String get killedByEmoji {
    switch (killedBy) {
      case 'HITMAN':
        return '🎯';
      case 'BOUNTY_HUNTER':
        return '🦯';
      case 'MAFIA':
      default:
        return '🔫';
    }
  }
}
