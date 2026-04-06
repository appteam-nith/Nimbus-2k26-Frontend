import 'package:flutter/material.dart';
import '../services/pusher_service.dart';
import '../models/chat_model.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Subscribe to the Pusher stream you built
    PusherService.instance.onChatMessage.listen((data) {
      if (mounted) {
        setState(() {
          _messages.insert(0, ChatMessage.fromJson(data));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true, // Newest messages at bottom
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return ListTile(
                title: Text(msg.senderName, 
                  style: TextStyle(color: msg.isMafia ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)),
                subtitle: Text(msg.message, style: const TextStyle(color: Colors.white)),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.white54)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () {
                  // TODO: Call your API to send message
                  _controller.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}