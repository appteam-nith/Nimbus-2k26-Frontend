import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../widgets/player_grid.dart';
import '../widgets/vote_button.dart';
import '../widgets/linear_phase_timer.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playThriller();
  }

  Future<void> _playThriller() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/thriller.mpeg'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final myVoteTarget = controller.myVoteTarget;
    final hasVoted = controller.isLoading; // Prevent spam

    final me = controller.players.firstWhere(
      (p) => p.userId == controller.myUserId,
      orElse: () => const PlayerModel(
        playerId: '',
        userId: '',
        name: '',
        status: PlayerStatus.ELIMINATED,
      ),
    );
    final isAlive = me.isAlive;

    // Only allow voting if phase is VOTING and player is alive
    final canVote =
        !hasVoted && controller.status == GameStatus.VOTING && isAlive;

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: LinearPhaseTimer(
                    endTime: DateTime.now().add(
                      Duration(
                        seconds: controller.timeRemaining > 0
                            ? controller.timeRemaining
                            : 10,
                      ),
                    ),
                    height: 6,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PlayerGrid(
                      players: controller.players,
                      myUserId: controller.myUserId,
                      selectedUserId: controller.myVoteTarget,
                      onTap: controller.setVoteTarget,
                      showRoles: controller.devMode,
                      voteCounts: controller.voteTally,
                      allowSelfSelect: true,
                      leftPlayerIds: controller.leftPlayerIds,
                    ),
                  ),
                ),

                // Info/Error Message
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildErrorBanner(controller.error!),
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
                          accentColor: const Color(
                            0xFFEF4444,
                          ), // Red for eliminate
                          onPressed: () {
                            if (canVote && myVoteTarget != null) {
                              controller.submitVote('DAY_LYNCH');
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SkipVoteButton(
                        isDisabled: !canVote,
                        onPressed: () {
                          if (canVote) {
                            controller.submitVote('DAY_LYNCH', isSkip: true);
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
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    final isBountyInfo = message.contains(
      'Bounty Hunter kill is not yet unlocked',
    );
    final isEliminatedInfo =
        isBountyInfo ||
        message.toLowerCase().contains('eliminated') ||
        message.toLowerCase().contains('cannot target');

    String displayMessage = message;
    if (isBountyInfo && displayMessage.startsWith('GameApiException(409):')) {
      displayMessage = displayMessage
          .replaceFirst('GameApiException(409):', '')
          .trim();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isEliminatedInfo
            ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
            : Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEliminatedInfo
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : Colors.redAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEliminatedInfo ? Icons.info_outline : Icons.error_outline,
            size: 18,
            color: isEliminatedInfo
                ? const Color(0xFFFCD34D)
                : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                displayMessage,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: isEliminatedInfo
                      ? const Color(0xFFFCD34D)
                      : Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
