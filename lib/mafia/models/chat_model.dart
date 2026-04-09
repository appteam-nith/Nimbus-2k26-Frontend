class ChatMessage {
  final String senderId; // userId from backend  ('system' for system messages)
  final String senderName; // full_name from backend
  final String message;
  final String channel; // 'global' | 'mafia' | 'doc'
  final DateTime timestamp;
  final bool isSystem; // true → system/event notification, not a player message

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    this.channel = 'global',
    required this.timestamp,
    this.isSystem = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['userId'] as String? ?? '',
      senderName: json['name'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      channel: json['channel'] as String? ?? 'global',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }
}
