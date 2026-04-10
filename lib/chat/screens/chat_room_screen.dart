import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../models/chat_message.dart';
import '../providers/community_chat_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomName;

  const ChatRoomScreen({super.key, required this.roomName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _joined = false;
  CommunityChatProvider? _joinedChatProvider;
  String? _joinedUserId;
  String? _joinedNickname;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinCurrentRoom();
    });
  }

  @override
  void dispose() {
    if (_joined && _joinedChatProvider != null && _joinedUserId != null) {
      _joinedChatProvider!.leaveRoom(
        roomName: widget.roomName,
        userId: _joinedUserId!,
        nickname: _joinedNickname,
      );
    }
    _messageController.dispose();
    super.dispose();
  }

  String _currentUserId(AuthProvider auth) {
    final firebaseUid = auth.user?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) return firebaseUid;
    final email = auth.userEmail;
    if (email != null && email.isNotEmpty) return email;
    return 'local-user';
  }

  Future<void> _joinCurrentRoom() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final chat = context.read<CommunityChatProvider>();
    final userId = _currentUserId(auth);

    final nickname = auth.userNickname?.trim();
    if (nickname == null || nickname.isEmpty) return;

    final error = await chat.joinRoom(
      roomName: widget.roomName,
      userId: userId,
      nickname: nickname,
    );
    if (!mounted) return;
    if (error == null) {
      _joined = true;
      _joinedChatProvider = chat;
      _joinedUserId = userId;
      _joinedNickname = nickname;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showParticipantsSheet(List<String> participants) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'People in room (${participants.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (participants.isEmpty)
                  const Text(
                    'No active participants.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...participants.map(
                    (name) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(name),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

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
    if (ok) {
      await chat.joinRoom(
        roomName: widget.roomName,
        userId: _currentUserId(auth),
        nickname: nickname,
      );
      if (!mounted) return;
    }
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

  Future<void> _toggleRoomLock({
    required CommunityChatProvider chat,
    required AuthProvider auth,
    required bool currentlyLocked,
  }) async {
    String? password;
    if (!currentlyLocked) {
      final controller = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Lock room'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Set room password',
                hintText: 'At least 4 characters',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: const Text('Lock'),
              ),
            ],
          );
        },
      );
      controller.dispose();
      if (!mounted || entered == null) return;
      password = entered;
    }

    final error = await chat.updateRoomLock(
      roomName: widget.roomName,
      requesterUserId: _currentUserId(auth),
      shouldLock: !currentlyLocked,
      password: password,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (currentlyLocked
                  ? 'Room unlocked successfully.'
                  : 'Room locked successfully.'),
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

    final error = await chat.sendMessage(
      roomName: widget.roomName,
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
        final room = chat.roomByName(widget.roomName);
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat Room')),
            body: const Center(child: Text('Room not found.')),
          );
        }

        final myNickname = auth.userNickname?.trim() ?? '';
        final participants = chat.participantsInRoom(room.name);
        final canManageLock = room.createdById == _currentUserId(auth);

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              IconButton(
                tooltip: 'Participants',
                onPressed: () => _showParticipantsSheet(participants),
                icon: const Icon(Icons.groups_outlined),
              ),
              if (canManageLock)
                IconButton(
                  tooltip: room.isLocked ? 'Unlock room' : 'Lock room',
                  onPressed: () => _toggleRoomLock(
                    chat: chat,
                    auth: auth,
                    currentlyLocked: room.isLocked,
                  ),
                  icon: Icon(room.isLocked ? Icons.lock : Icons.lock_open),
                ),
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
                child: Text(
                  room.isLocked
                      ? 'Locked room: password required to enter'
                      : 'Created by ${room.createdByName} • ${participants.length} online',
                  style: const TextStyle(
                    color: Color(0xFF1A3BB3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: room.messages.isEmpty
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
                        itemCount: room.messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              room.messages[room.messages.length - 1 - index];
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
