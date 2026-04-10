import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../models/chat_room.dart';
import '../providers/community_chat_provider.dart';
import 'chat_room_screen.dart';

class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CommunityChatProvider>().ensureInitialized();
      if (!mounted) return;
      await _ensureNickname(required: true);
    });
  }

  String _currentUserId(AuthProvider auth) {
    final firebaseUid = auth.user?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) return firebaseUid;
    final email = auth.userEmail;
    if (email != null && email.isNotEmpty) return email;
    return 'local-user';
  }

  Future<void> _ensureNickname({required bool required}) async {
    final auth = context.read<AuthProvider>();
    final existing = auth.userNickname?.trim() ?? '';

    if (!required) {
      final nickname = await _showNicknameDialog(
        required: false,
        currentNickname: existing,
      );
      if (!mounted || nickname == null) return;

      final ok = await auth.updateNickname(nickname);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Chat nickname updated.'
                : (auth.errorMessage ?? 'Unable to update nickname.'),
          ),
        ),
      );
      return;
    }

    if (existing.isNotEmpty) return;

    while (mounted) {
      final nickname = await _showNicknameDialog(
        required: required,
        currentNickname: auth.userNickname ?? '',
      );

      if (!mounted) return;
      if (nickname == null) {
        if (!required) return;
        continue;
      }

      final ok = await auth.updateNickname(nickname);
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat nickname updated.')));
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Unable to update nickname.'),
        ),
      );

      if (!required) return;
    }
  }

  Future<String?> _showNicknameDialog({
    required bool required,
    required String currentNickname,
  }) async {
    var nicknameValue = currentNickname;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: !required,
      builder: (dialogContext) {
        return PopScope(
          canPop: !required,
          child: AlertDialog(
            title: Text(required ? 'Set Chat Nickname' : 'Change Nickname'),
            content: TextFormField(
              initialValue: currentNickname,
              maxLength: 24,
              autofocus: true,
              onChanged: (value) => nicknameValue = value,
              decoration: const InputDecoration(
                hintText: 'Enter nickname',
                helperText: 'This name is shown in chat rooms.',
              ),
            ),
            actions: [
              if (!required)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancel'),
                ),
              ElevatedButton(
                onPressed: () {
                  final value = nicknameValue.trim();
                  if (value.isEmpty) return;
                  Navigator.of(dialogContext).pop(value);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    return result;
  }

  Future<void> _showCreateRoomDialog(
    CommunityChatProvider chat,
    AuthProvider auth,
  ) async {
    final rootMessenger = ScaffoldMessenger.of(context);
    var roomValue = '';
    var passwordValue = '';
    var lockRoom = false;

    final createdRoomName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Create Chat Room'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) => roomValue = value,
                      decoration: const InputDecoration(
                        labelText: 'Room name',
                        hintText: 'Example: Hostel D Block',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: lockRoom,
                      onChanged: (value) {
                        setLocalState(() => lockRoom = value);
                      },
                      title: const Text('Lock room with password'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (lockRoom) ...[
                      const SizedBox(height: 4),
                      TextField(
                        obscureText: true,
                        onChanged: (value) => passwordValue = value,
                        decoration: const InputDecoration(
                          labelText: 'Room password',
                          hintText: 'At least 4 characters',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nickname = auth.userNickname?.trim();
                    if (nickname == null || nickname.isEmpty) {
                      rootMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Set your nickname before creating a room.',
                          ),
                        ),
                      );
                      return;
                    }

                    final error = await chat.createRoom(
                      name: roomValue,
                      createdById: _currentUserId(auth),
                      createdByName: nickname,
                      lockRoom: lockRoom,
                      password: passwordValue,
                    );

                    if (error != null) {
                      rootMessenger.showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }

                    final roomName = roomValue.trim();
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(roomName);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || createdRoomName == null) return;
    final room = chat.roomByName(createdRoomName);
    if (room != null) {
      await _openRoom(room);
    }
  }

  Future<void> _openRoom(CommunityChatRoom room) async {
    if (room.isLocked && !room.isPublic) {
      var enteredValue = '';
      final enteredPassword = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('${room.name} is locked'),
            content: TextField(
              obscureText: true,
              onChanged: (value) => enteredValue = value,
              decoration: const InputDecoration(
                labelText: 'Enter room password',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(enteredValue);
                },
                child: const Text('Join'),
              ),
            ],
          );
        },
      );

      if (!mounted || enteredPassword == null) return;
      final ok = await context.read<CommunityChatProvider>().verifyRoomPassword(
        roomName: room.name,
        password: enteredPassword,
      );

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect room password.')),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(roomName: room.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CommunityChatProvider>(
      builder: (context, auth, chat, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Community Chat'),
            actions: [
              IconButton(
                tooltip: 'Change nickname',
                onPressed: () => _ensureNickname(required: false),
                icon: const Icon(Icons.badge_outlined),
              ),
            ],
          ),
          body: chat.isInitialized
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Signed in as ${auth.userNickname ?? 'No nickname'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3BB3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...chat.rooms.map(
                      (room) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _openRoom(room),
                          leading: CircleAvatar(
                            backgroundColor: room.isPublic
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFEFF4FF),
                            child: Icon(
                              room.isPublic
                                  ? Icons.public
                                  : room.isLocked
                                  ? Icons.lock_outline
                                  : Icons.chat_bubble_outline,
                              color: room.isPublic
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF1A3BB3),
                            ),
                          ),
                          title: Text(room.name),
                          subtitle: Text(
                            room.isPublic
                                ? 'Always open'
                                : 'Created by ${room.createdByName}',
                          ),
                          trailing: room.isLocked && !room.isPublic
                              ? const Icon(Icons.key, size: 18)
                              : const Icon(Icons.arrow_forward_ios, size: 14),
                        ),
                      ),
                    ),
                    if (chat.customRooms.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No custom rooms yet. Tap Create Room to start.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateRoomDialog(chat, auth),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Create Room'),
          ),
        );
      },
    );
  }
}
