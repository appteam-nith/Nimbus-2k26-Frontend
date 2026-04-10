import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../models/chat_message.dart';
import '../providers/community_chat_provider.dart';

class PublicChatScreen extends StatefulWidget {
  const PublicChatScreen({super.key});

  @override
  State<PublicChatScreen> createState() => _PublicChatScreenState();
}

class _PublicChatScreenState extends State<PublicChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _updateNickname(AuthProvider auth) async {
    final chat = context.read<CommunityChatProvider>();
    final controller = TextEditingController(text: auth.userNickname ?? '');
    final nickname = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Nickname'),
          content: TextField(
            controller: controller,
            maxLength: 24,
            decoration: const InputDecoration(hintText: 'Enter nickname'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || nickname == null) return;
    final ok = await auth.updateNickname(nickname);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Nickname updated.'
              : (auth.errorMessage ?? 'Unable to update nickname.'),
        ),
      ),
    );
  }

  Future<void> _sendMessage(
    CommunityChatProvider chat,
    AuthProvider auth,
  ) async {
    final nickname = auth.userNickname?.trim();
    if (nickname == null || nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set a nickname before sending messages.'),
        ),
      );
      await _updateNickname(auth);
      return;
    }

    final error = await chat.sendPublicMessage(
      senderNickname: nickname,
      text: _messageController.text,
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _messageController.clear();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CommunityChatProvider>(
      builder: (context, auth, chat, _) {
        final myNickname = auth.userNickname?.trim() ?? '';
        final messages = chat.publicMessages;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Public Chat'),
            actions: [
              IconButton(
                tooltip: 'Change nickname',
                onPressed: () => _updateNickname(auth),
                icon: const Icon(Icons.badge_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFEFF4FF),
                child: const Text(
                  'Public room (always open)',
                  style: TextStyle(
                    color: Color(0xFF1A3BB3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              messages[messages.length - 1 - index];
                          return _MessageTile(
                            message: message,
                            isMe:
                                !message.isSystem &&
                                message.senderNickname == myNickname,
                            formatTime: _formatTime,
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(chat, auth),
                          decoration: InputDecoration(
                            hintText:
                                'Type message as ${myNickname.isEmpty ? 'Guest' : myNickname}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        width: 46,
                        child: ElevatedButton(
                          onPressed: () => _sendMessage(chat, auth),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.send),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  final CommunityChatMessage message;
  final bool isMe;
  final String Function(DateTime) formatTime;

  const _MessageTile({
    required this.message,
    required this.isMe,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1A3BB3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderNickname,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMe ? const Color(0xFFC7D2FE) : const Color(0xFF1A3BB3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              formatTime(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
