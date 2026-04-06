// ignore_for_file: constant_identifier_names

/// Lightweight payload from the `vote-updated` Pusher event.
/// The backend intentionally broadcasts WHO voted but NOT who they targeted —
/// only that an action was taken. This allows the UI to show "3/5 voted" etc.
class VoteModel {
  final String voterId;
  final VoteType voteType;

  const VoteModel({
    required this.voterId,
    required this.voteType,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      voterId: json['voterId'] as String,
      voteType: VoteType.values.firstWhere(
        (v) => v.name == json['voteType'],
        orElse: () => VoteType.DAY_LYNCH,
      ),
    );
  }
}

// ─── ENUM ─────────────────────────────────────────────────────────────────────

enum VoteType {
  DAY_LYNCH,
  MAFIA_TARGET,
  DOC_SAVE,
  COP_INVESTIGATE,
  NURSE_ACTION;

  /// Maps to the game phase in which this vote type is valid.
  String get requiredPhase {
    switch (this) {
      case VoteType.DAY_LYNCH:
        return 'VOTING';
      case VoteType.MAFIA_TARGET:
      case VoteType.DOC_SAVE:
      case VoteType.COP_INVESTIGATE:
      case VoteType.NURSE_ACTION:
        return 'NIGHT';
    }
  }
}
