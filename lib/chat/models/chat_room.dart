import 'chat_message.dart';

class CommunityChatRoom {
  final String id;
  final String name;
  final bool isPublic;
  final String createdById;
  final String createdByName;
  bool isLocked;
  String? password;
  final DateTime createdAt;
  final List<CommunityChatMessage> messages;

  CommunityChatRoom({
    this.id = '',
    required this.name,
    required this.isPublic,
    required this.createdById,
    required this.createdByName,
    required this.isLocked,
    required this.password,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPublic': isPublic,
      'createdById': createdById,
      'createdByName': createdByName,
      'isLocked': isLocked,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory CommunityChatRoom.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final parsedMessages = <CommunityChatMessage>[];
    if (rawMessages is List) {
      for (final raw in rawMessages) {
        if (raw is Map<String, dynamic>) {
          parsedMessages.add(CommunityChatMessage.fromJson(raw));
        } else if (raw is Map) {
          parsedMessages.add(
            CommunityChatMessage.fromJson(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return CommunityChatRoom(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isPublic: json['isPublic'] == true,
      createdById: (json['createdById'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '').toString(),
      isLocked: json['isLocked'] == true,
      password: json['password']?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      messages: parsedMessages,
    );
  }
}
