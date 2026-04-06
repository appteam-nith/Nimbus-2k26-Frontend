class ChatMessage {
  final String senderName;
  final String message;
  final bool isMafia;
  final DateTime timestamp;

  ChatMessage({
    required this.senderName,
    required this.message,
    this.isMafia = false,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderName: json['senderName'] ?? 'Unknown',
      message: json['message'] ?? '',
      isMafia: json['isMafia'] ?? false,
      timestamp: DateTime.now(),
    );
  }
}