class CommunityChatMessage {
  final String id;
  final String? roomName;
  final String senderNickname;
  final String text;
  final DateTime sentAt;
  final bool isSystem;

  const CommunityChatMessage({
    this.id = '',
    this.roomName,
    required this.senderNickname,
    required this.text,
    required this.sentAt,
    this.isSystem = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomName': roomName,
      'senderNickname': senderNickname,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
      'isSystem': isSystem,
    };
  }

  factory CommunityChatMessage.fromJson(Map<String, dynamic> json) {
    return CommunityChatMessage(
      id: json['id']?.toString() ?? '',
      roomName: json['roomName'] as String?,
      senderNickname: (json['senderNickname'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      sentAt:
          DateTime.tryParse((json['sentAt'] ?? '').toString()) ??
          DateTime.now(),
      isSystem: json['isSystem'] == true,
    );
  }
}
