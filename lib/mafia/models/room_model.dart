import 'player_model.dart';

// ignore_for_file: constant_identifier_names

/// Full room snapshot returned by GET /api/game/rooms/:code
class RoomModel {
  final String roomCode;
  final String hostId;
  final GameStatus status;
  final int round;
  final String roomSize; // "FIVE" | "EIGHT" | "TWELVE"
  final GameRole? myRole;
  final String? winner; // "MAFIA" | "CITIZENS" | null
  final String? eliminatedThisRound; // GamePlayer.id of who was eliminated
  final DateTime? phaseEndsAt;
  final int? timeRemaining; // seconds, precomputed by server
  final List<PlayerModel> players;
  /// True if the Nurse has already found the Doctor this game.
  final bool nurseMet;
  /// True if the Reporter has already used their one-time broadcast this game.
  final bool reporterUsed;
  /// True if this room was started in developer mode (bots fill empty slots).
  final bool devMode;

  const RoomModel({
    required this.roomCode,
    required this.hostId,
    required this.status,
    required this.round,
    required this.roomSize,
    this.myRole,
    this.winner,
    this.eliminatedThisRound,
    this.phaseEndsAt,
    this.timeRemaining,
    required this.players,
    this.nurseMet = false,
    this.reporterUsed = false,
    this.devMode = false,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.LOBBY,
      ),
      round: json['round'] as int? ?? 0,
      roomSize: json['roomSize'] as String? ?? 'FIVE',
      myRole: json['myRole'] != null
          ? GameRole.values.firstWhere(
              (r) => r.name == json['myRole'],
              orElse: () => GameRole.CITIZEN,
            )
          : null,
      winner: json['winner'] as String?,
      eliminatedThisRound: json['eliminatedThisRound'] as String?,
      phaseEndsAt: json['phaseEndsAt'] != null
          ? DateTime.tryParse(json['phaseEndsAt'] as String)
          : null,
      timeRemaining: json['timeRemaining'] as int?,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      nurseMet: json['nurseMet'] as bool? ?? false,
      reporterUsed: json['reporterUsed'] as bool? ?? false,
      devMode: json['devMode'] as bool? ?? false,
    );
  }

  bool get isActive => status != GameStatus.ENDED && status != GameStatus.LOBBY;

  /// Returns the player whose GamePlayer.id matches [eliminatedThisRound]
  /// so reveal screens can display their name/role.
  PlayerModel? get eliminatedPlayer {
    if (eliminatedThisRound == null) return null;
    // eliminatedThisRound is GamePlayer.id, not user_id.
    // We identify by checking players list (server returns id as userId here).
    try {
      return players.firstWhere((p) => p.userId == eliminatedThisRound);
    } catch (_) {
      return null;
    }
  }
}

// ─── GAME STATUS ENUM ─────────────────────────────────────────────────────────

enum GameStatus {
  LOBBY,
  NIGHT,
  DISCUSSION,
  VOTING,
  REVEAL,
  ENDED;

  bool get isNightPhase => this == GameStatus.NIGHT;
  bool get isDayPhase =>
      this == GameStatus.DISCUSSION || this == GameStatus.VOTING;
}
