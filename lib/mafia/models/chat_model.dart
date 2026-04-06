class ChatMessage {
  final String senderId;   // userId from backend
  final String senderName; // full_name from backend
  final String message;
  final String channel;    // 'global' | 'mafia' | 'doc'
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    this.channel = 'global',
    required this.timestamp,
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
    );
  }
}