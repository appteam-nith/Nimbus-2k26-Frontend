// ignore_for_file: constant_identifier_names

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
  REPORTER,
  PROPHET;

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
      case GameRole.REPORTER:
        return 'Reporter';
      case GameRole.PROPHET:
        return 'Prophet';
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
        return 'Select 2 targets and guess 2 roles. Eliminate both if correct!';
      case GameRole.BOUNTY_HUNTER:
        return 'Night 1: Select a VIP. Later, survive and kill on command.';
      case GameRole.REPORTER:
        return 'Broadcast a player\'s secret alignment to the village once per game.';
      case GameRole.PROPHET:
        return 'Your foresight dominates the discussion phases.';
    }
  }

  bool get isMafia =>
      this == GameRole.MAFIA || this == GameRole.MAFIA_HELPER;
}
