import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/chat_model.dart';
import '../services/pusher_service.dart';
import '../services/game_api.dart';

/// Full-featured realtime chat widget.
///
/// Supports:
///   • Global chat (DISCUSSION phase)
///   • Team chat (Mafia / Doc-Nurse) via [teamChannel]
///   • Realtime Pusher messages via PusherService.onChatMessage
///   • Timestamps, sender avatars, send-on-Enter
class ChatWidget extends StatefulWidget {
  /// Null → global chat. 'mafia' or 'doc' → team chat.
  final String? teamChannel;

  const ChatWidget({super.key, this.teamChannel});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = PusherService.instance.onChatMessage.listen(_onMessage);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    // Filter by channel: global widget only shows global, team widget only shows its channel
    final msgChannel = data['channel'] as String? ?? 'global';
    final expectedChannel = widget.teamChannel ?? 'global';
    if (msgChannel != expectedChannel) return;

    setState(() {
      _messages.insert(0, ChatMessage.fromJson(data));
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final gc = context.read<GameController>();
    if (gc.roomCode == null) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await GameApi.instance.sendChat(
        gc.roomCode!,
        text,
        channel: widget.teamChannel,
      );
      _textController.clear();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showPlayersList() {
    final gc = context.read<GameController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2333),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PLAYERS IN ROOM',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: gc.players.length,
                  itemBuilder: (context, index) {
                    final p = gc.players[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.isAlive ? Colors.blue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                          child: Text(
                            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: TextStyle(color: p.isAlive ? Colors.blueAccent : Colors.redAccent),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                             color: p.isAlive ? Colors.white : Colors.white54,
                             decoration: p.isAlive ? null : TextDecoration.lineThrough,
                             fontFamily: 'Inter',
                             fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: p.isAlive 
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                            : const Icon(Icons.cancel, color: Colors.red, size: 16),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<GameController>().myUserId;
    final channelLabel = _channelLabel();
    final channelColor = _channelColor();

    return Column(
      children: [
        // ── Channel label ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: channelColor.withValues(alpha: 0.08),
            border: Border(
              top: BorderSide(color: channelColor.withValues(alpha: 0.2)),
              bottom: BorderSide(color: channelColor.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: channelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: channelColor.withValues(alpha: 0.5),
                        blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                channelLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: channelColor,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${_messages.length} messages',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),

        // ── Messages ──────────────────────────────────────────────────────────
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '💬',
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.senderId == myUserId;
                    return _MessageBubble(
                      msg: msg,
                      isMe: isMe,
                      channelColor: channelColor,
                    );
                  },
                ),
        ),

        // ── Error ─────────────────────────────────────────────────────────────
        if (_error != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _error = null),
                  child: const Icon(Icons.close,
                      size: 14, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ),

        // ── Input ─────────────────────────────────────────────────────────────
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2333),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Say something...',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white54, size: 20),
                          onPressed: _showPlayersList,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? Colors.white12
                          : channelColor,
                      shape: BoxShape.circle,
                      boxShadow: _isSending
                          ? null
                          : [
                              BoxShadow(
                                color:
                                    channelColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              )
                            ],
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _channelLabel() {
    switch (widget.teamChannel) {
      case 'mafia':
        return '🔫  MAFIA CHAT — PRIVATE';
      case 'doc':
        return '💉  DOCTOR – NURSE CHANNEL';
      default:
        return '💬  GLOBAL CHAT';
    }
  }

  Color _channelColor() {
    switch (widget.teamChannel) {
      case 'mafia':
        return const Color(0xFFEF4444);
      case 'doc':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF135BEC);
    }
  }
}

// ─── MESSAGE BUBBLE ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final Color channelColor;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.channelColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = msg.senderName.isNotEmpty
        ? msg.senderName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: channelColor.withValues(alpha: 0.2),
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: channelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      msg.senderName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: channelColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe
                        ? channelColor.withValues(alpha: 0.18)
                        : const Color(0xFF1C2333),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isMe ? 16 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? channelColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    msg.message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(msg.timestamp),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}