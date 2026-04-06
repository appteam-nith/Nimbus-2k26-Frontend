/// Mirrors the backend GamePlayer shape returned by getRoomState.
/// [role] is only populated for the calling player themselves,
/// or for ALL players once the game has ENDED.
class PlayerModel {
  final String userId;
  final String name;
  final PlayerStatus status;
  final GameRole? role;

  const PlayerModel({
    required this.userId,
    required this.name,
    required this.status,
    this.role,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      status: PlayerStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PlayerStatus.ALIVE,
      ),
      role: json['role'] != null
          ? GameRole.values.firstWhere(
              (r) => r.name == json['role'],
              orElse: () => GameRole.CITIZEN,
            )
          : null,
    );
  }

  bool get isAlive => status == PlayerStatus.ALIVE;
  bool get isEliminated => status == PlayerStatus.ELIMINATED;

  PlayerModel copyWith({
    String? userId,
    String? name,
    PlayerStatus? status,
    GameRole? role,
  }) {
    return PlayerModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      status: status ?? this.status,
      role: role ?? this.role,
    );
  }
}

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum PlayerStatus { ALIVE, ELIMINATED }

enum GameRole {
  MAFIA,
  MAFIA_HELPER,
  CITIZEN,
  DOCTOR,
  COP,
  NURSE,
  HITMAN,
  BOUNTY_HUNTER,
  PROPHET,
  REPORTER;

  /// Human-readable name for display
  String get displayName {
    switch (this) {
      case GameRole.MAFIA:
        return 'Mafia';
      case GameRole.MAFIA_HELPER:
        return 'Mafia Helper';
      case GameRole.CITIZEN:
        return 'Citizen';
      case GameRole.DOCTOR:
        return 'Doctor';
      case GameRole.COP:
        return 'Cop';
      case GameRole.NURSE:
        return 'Nurse';
      case GameRole.HITMAN:
        return 'Hitman';
      case GameRole.BOUNTY_HUNTER:
        return 'Bounty Hunter';
      case GameRole.PROPHET:
        return 'Prophet';
      case GameRole.REPORTER:
        return 'Reporter';
    }
  }

  /// Short ability description shown on the role card
  String get description {
    switch (this) {
      case GameRole.MAFIA:
        return 'Each night, vote with your team to eliminate a citizen.';
      case GameRole.MAFIA_HELPER:
        return 'Assist the Mafia. Your vote counts toward the night kill.';
      case GameRole.CITIZEN:
        return 'Survive, observe, and expose the Mafia during discussion.';
      case GameRole.DOCTOR:
        return 'Each night, protect one player from elimination.';
      case GameRole.COP:
        return 'Each night, investigate one player — learn if they are Mafia.';
      case GameRole.NURSE:
        return 'Find the Doctor. Once you meet, the Doctor gains extra protection.';
      case GameRole.HITMAN:
        return 'At T-5s each night, guess 2 players and their roles. Kill both if correct — but you cannot target the Cop.';
      case GameRole.BOUNTY_HUNTER:
        return 'Night 1: pick your VIP. If your VIP dies, your kill button unlocks — use it wisely.';
      case GameRole.PROPHET:
        return 'You can see one step into the future. Your visions override the final death list.';
      case GameRole.REPORTER:
        return 'Once per game, broadcast a player\'s true role to the entire town. Use it to expose — or mislead.';
    }
  }

  bool get isMafia =>
      this == GameRole.MAFIA || this == GameRole.MAFIA_HELPER;

  bool get isSpecial =>
      this == GameRole.HITMAN ||
      this == GameRole.BOUNTY_HUNTER ||
      this == GameRole.PROPHET ||
      this == GameRole.REPORTER;
}
