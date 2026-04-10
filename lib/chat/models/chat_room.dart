import 'chat_message.dart';

class CommunityChatRoom {
  final String id;
  final String name;
  final String createdById;
  final String createdByName;
  bool isLocked;
  String? password;
  final DateTime createdAt;
  final List<CommunityChatMessage> messages;
  final List<String> members;

  CommunityChatRoom({
    this.id = '',
    required this.name,
    required this.createdById,
    required this.createdByName,
    required this.isLocked,
    required this.password,
    required this.createdAt,
    required this.messages,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdById': createdById,
      'createdByName': createdByName,
      'isLocked': isLocked,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'members': members,
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
      createdById: (json['createdById'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '').toString(),
      isLocked: json['isLocked'] == true,
      password: json['password']?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      messages: parsedMessages,
      members: (json['members'] as List<dynamic>?)?.map((m) => m['nickname'].toString()).toList() ?? [],
    );
  }
}
