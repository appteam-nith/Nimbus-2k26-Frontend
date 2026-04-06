import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../widgets/phase_timer.dart';
import '../widgets/chat_widget.dart';
import '../services/pusher_service.dart'; // NEW: For connection status

class DiscussionScreen extends StatelessWidget {
  const DiscussionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    
    // DEV 3: Connection check to show if Pusher is live
    final isConnected = PusherService.instance.isConnected; 

    return Scaffold(
      backgroundColor: const Color(0xFF0D121B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text("DISCUSSION", 
              style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold)),
            // Connection Dot
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(isConnected ? "LIVE" : "RECONNECTING...", 
                  style: TextStyle(color: isConnected ? Colors.green : Colors.red, fontSize: 10)),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              // SYNCED TIMER: Uses the public getter we just added to GameController
              Center(
                child: PhaseTimer(
                  endTime: game.phaseEndsAt ?? DateTime.now().add(const Duration(seconds: 30)),
                  size: 100,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  game.status.name == "DISCUSSION" 
                      ? "Who is the Mafia? Convince the others!" 
                      : "Waiting for next phase...",
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ),
              // THE REALTIME CHAT
              const Expanded(child: ChatWidget()),
            ],
          ),
          
          // DEV 3: Loading overlay if the game is processing a transition
          if (game.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}