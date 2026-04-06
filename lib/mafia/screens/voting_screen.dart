import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../widgets/player_grid.dart';
import '../widgets/vote_button.dart';
import '../widgets/phase_timer.dart';

class VotingScreen extends StatelessWidget {
  const VotingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final myVoteTarget = controller.myVoteTarget;
    final hasVoted = controller.isLoading; // Prevent spam

    final me = controller.players.firstWhere(
      (p) => p.userId == controller.myUserId, 
      orElse: () => const PlayerModel(userId: '', name: '', status: PlayerStatus.ELIMINATED)
    );
    final isAlive = me.isAlive;

    // Only allow voting if phase is VOTING and player is alive
    final canVote = !hasVoted && controller.status == GameStatus.VOTING && isAlive;

    return Scaffold(
      backgroundColor: const Color(0xFF0D121B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Vote to Eliminate',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Round ${controller.round}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Timer
                if (controller.timeRemaining > 0)
                  PhaseTimer(
                    endTime: DateTime.now().add(Duration(seconds: controller.timeRemaining)),
                    size: 80,
                  ),
                  
                const SizedBox(height: 32),

                // Player Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PlayerGrid(
                      players: controller.players,
                      myUserId: controller.myUserId,
                      selectedUserId: controller.myVoteTarget,
                      onTap: controller.setVoteTarget,
                      showRoles: false, // Don't show roles during voting
                    ),
                  ),
                ),

                // Error Message if any
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),

                // Controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: VoteButton(
                          label: myVoteTarget != null 
                              ? 'Lynch Selected Player' 
                              : 'Select a player',
                          isSelected: myVoteTarget != null,
                          isDisabled: !canVote || myVoteTarget == null,
                          accentColor: const Color(0xFFEF4444), // Red for eliminate
                          onPressed: () {
                            if (canVote && myVoteTarget != null) {
                              controller.submitVote('LYNCH');
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SkipVoteButton(
                        isDisabled: !canVote,
                        onPressed: () {
                          if (canVote) {
                            controller.submitVote('LYNCH', isSkip: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (controller.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
