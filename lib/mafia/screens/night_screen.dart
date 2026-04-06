import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../widgets/player_grid.dart';
import '../widgets/vote_button.dart';
import '../widgets/phase_timer.dart';
import '../widgets/dev_role_board.dart';

class NightScreen extends StatefulWidget {
  const NightScreen({super.key});

  @override
  State<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends State<NightScreen> {
  // Hitman multi-select tracking
  List<String> _hitmanTargets = [];
  String? _hitmanRoleGuess1;
  String? _hitmanRoleGuess2;

  // Single use lock tracking for COP and REPORTER
  bool _hasLockedAction = false;

  // Single select fallback if gameController's myVoteTarget isn't enough
  // but we usually rely on GameController for single selects.

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final myRole = controller.myRole ?? GameRole.CITIZEN;
    final isNight = controller.status == GameStatus.NIGHT;
    
    final me = controller.players.firstWhere(
      (p) => p.userId == controller.myUserId, 
      orElse: () => const PlayerModel(userId: '', name: '', status: PlayerStatus.ELIMINATED)
    );
    final isAlive = me.isAlive;
    final myVoteTarget = controller.myVoteTarget;
    final hasVoted = controller.isLoading;

    // Hitman Lockout (T-5s)
    final hitmanLocked = myRole == GameRole.HITMAN && controller.timeRemaining <= 5;
    // Single-use lock: seed from controller on first build (covers reconnect)
    if (!_hasLockedAction && controller.reporterUsed && myRole == GameRole.REPORTER) {
      _hasLockedAction = true;
    }
    // General vote prevention
    final canVote = isNight && !hasVoted && isAlive && !hitmanLocked && !_hasLockedAction;

    // Config block
    String title = '';
    String subtitle = 'Wait for the night to end...';
    Color themeColor = const Color(0xFF135BEC);
    bool hasAction = false;
    String actionLabel = 'Select player';
    String voteType = '';
    Widget? customWidget;

    if (!isAlive) {
      title = 'You are Eliminated';
      subtitle = 'You cannot take action during the night.';
      hasAction = false;
    } else {
      switch (myRole) {
        case GameRole.MAFIA:
        case GameRole.MAFIA_HELPER:
          title = 'Mafia Kill';
          subtitle = 'Select a player to eliminate. Your team must agree.';
          themeColor = const Color(0xFFEF4444);
          hasAction = true;
          actionLabel = 'Assassinate Player';
          voteType = 'MAFIA_TARGET';
          break;
        case GameRole.DOCTOR:
          title = 'Medical Save';
          subtitle = 'Select a player to protect tonight.';
          themeColor = const Color(0xFF22C55E);
          hasAction = true;
          actionLabel = 'Protect Player';
          voteType = 'DOC_SAVE';
          break;
        case GameRole.COP:
          title = 'Investigation';
          subtitle = 'Select a player to investigate their alignment. (Once per night)';
          themeColor = const Color(0xFF3B82F6);
          hasAction = true;
          actionLabel = 'Investigate Player';
          voteType = 'COP_INVESTIGATE';
          break;
        case GameRole.NURSE:
          title = 'Find the Doctor';
          subtitle = controller.nurseMet
              ? 'You have found the Doctor. Assist them each night to keep them safe.'
              : 'If you select the Doctor, they become empowered.';
          themeColor = const Color(0xFF10B981);
          hasAction = true;
          actionLabel = controller.nurseMet ? 'Assist Doctor' : 'Assist Player';
          voteType = 'NURSE_SUPPORT';
          break;
        case GameRole.BOUNTY_HUNTER:
          if (controller.round == 1) {
            title = 'Bounty VIP';
            subtitle = 'Select the VIP you pledge to protect.';
            actionLabel = 'Pledge to VIP';
            voteType = 'BOUNTY_VIP';
          } else {
            title = 'Bounty Kill';
            subtitle = 'Select a player to hunt down.';
            actionLabel = 'Execute Target';
            voteType = 'BOUNTY_KILL';
          }
          themeColor = const Color(0xFFF59E0B);
          hasAction = true;
          break;
        case GameRole.REPORTER:
          title = 'Breaking News';
          subtitle = 'Select a player to globally reveal their alignment tomorrow morning. (One use only)';
          themeColor = const Color(0xFFD946EF);
          hasAction = true;
          actionLabel = 'Investigate & Broadcast';
          voteType = 'REPORTER_BROADCAST';
          break;
        case GameRole.PROPHET:
          title = 'Prophet\'s Rest';
          subtitle = 'Your power manifests during the day. Sleep now.';
          themeColor = const Color(0xFF9CA3AF);
          hasAction = false;
          break;
        case GameRole.HITMAN:
          title = 'Hitman Contract';
          subtitle = 'Select exactly two targets and guess their roles. Locks at T-5s.';
          themeColor = const Color(0xFF991B1B);
          hasAction = true;
          actionLabel = 'Execute Contract';
          voteType = 'HITMAN_STRIKE';
          customWidget = _buildHitmanUI(controller, canVote);
          break;
        case GameRole.CITIZEN:
          title = 'Citizens Sleep';
          subtitle = 'Wait silently for the sun to rise...';
          hasAction = false;
          themeColor = const Color(0xFF6B7280);
          break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Night Phase: Round ${controller.round}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
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
                const SizedBox(height: 16),
                // ── DevRoleBoard (dev mode only) ──────────────────────────
                // Injected below; the actual widget is in the Positioned overlay

                // Timer
                if (controller.timeRemaining > 0)
                  PhaseTimer(
                    endTime: DateTime.now().add(Duration(seconds: controller.timeRemaining)),
                    size: 80,
                  ),
                  
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main Interaction Area
                if (customWidget != null)
                  Expanded(child: customWidget)
                else if (hasAction)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PlayerGrid(
                        players: controller.players,
                        myUserId: controller.myUserId,
                        selectedUserId: myVoteTarget,
                        onTap: controller.setVoteTarget,
                        showRoles: false,
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Icon(
                        Icons.nights_stay,
                        size: 100,
                        color: Color(0xFF1F2937),
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

                // Controls (Standard)
                if (hasAction && customWidget == null)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: VoteButton(
                            label: myVoteTarget != null 
                                ? actionLabel 
                                : 'Select a player',
                            isSelected: myVoteTarget != null,
                            isDisabled: !canVote || myVoteTarget == null,
                            accentColor: themeColor,
                            onPressed: () async {
                              if (canVote && myVoteTarget != null) {
                                final result = await controller.submitVote(voteType);
                                if (result != null && mounted) {
                                  _showResultDialog(context, result);
                                }
                                
                                if (['COP_INVESTIGATE', 'REPORTER_BROADCAST'].contains(voteType) && mounted) {
                                  // Even if the result string is null, if the call didn't throw an error, we completed it
                                  if (controller.error == null) {
                                    setState(() => _hasLockedAction = true);
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SkipVoteButton(
                          isDisabled: !canVote,
                          onPressed: () {
                            if (canVote) {
                              controller.submitVote(voteType, isSkip: true);
                            }
                          },
                        ),
                      ],
                    ),
                  )
                // Controls (Hitman)
                else if (hasAction && customWidget != null)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: VoteButton(
                        label: _hitmanTargets.length == 2 && _hitmanRoleGuess1 != null && _hitmanRoleGuess2 != null
                            ? actionLabel 
                            : 'Select 2 Targets and Roles',
                        isSelected: _hitmanTargets.length == 2 && _hitmanRoleGuess1 != null && _hitmanRoleGuess2 != null,
                        isDisabled: !canVote || _hitmanTargets.length != 2 || _hitmanRoleGuess1 == null || _hitmanRoleGuess2 == null,
                        accentColor: themeColor,
                        onPressed: () {
                          if (canVote && _hitmanTargets.length == 2 && _hitmanRoleGuess1 != null && _hitmanRoleGuess2 != null) {
                            controller.submitVote(
                              voteType,
                              overrideTargets: _hitmanTargets,
                              overrideRoles: [_hitmanRoleGuess1!, _hitmanRoleGuess2!],
                            );
                          }
                        },
                      ),
                    ),
                  )
                else if (isAlive && myRole != GameRole.PROPHET)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF374151)),
                    ),
                  ),
              ],
            ),
          ),
          
          // ── Loading overlay ──────────────────────────────────────────────
          if (controller.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // ── Hitman Strike Overlay ──────────────────────────────────
          if (controller.hitmanStrikeEvent != null)
            _HitmanStrikeOverlay(
              data: controller.hitmanStrikeEvent!,
              players: controller.players,
              onDismiss: () {
                controller.hitmanStrikeEvent = null;
                controller.notifyListeners();
              },
            ),
          // ── Dev Mode Role Board overlay ────────────────────────────
          if (controller.devMode)
            DevRoleBoard(
              players: controller.players,
              myUserId: controller.myUserId,
            ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String resultMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Investigation Complete',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          resultMessage,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Understood',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF135BEC),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  // HITMAN COMPLEX UI BUILDER
  Widget _buildHitmanUI(GameController controller, bool canVote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Targets
          Text(
            'Select exactly 2 Targets:',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: controller.players.length,
            itemBuilder: (context, index) {
              final player = controller.players[index];
              final isMe = player.userId == controller.myUserId;
              final isEliminated = player.isEliminated;
              final isSelected = _hitmanTargets.contains(player.userId);

              return GestureDetector(
                onTap: (!canVote || isEliminated || isMe) ? null : () {
                  setState(() {
                    if (isSelected) {
                      _hitmanTargets.remove(player.userId);
                    } else if (_hitmanTargets.length < 2) {
                      _hitmanTargets.add(player.userId);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF991B1B).withOpacity(0.2) : const Color(0xFF1C2333),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF991B1B) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isEliminated ? const Color(0xFF374151) : const Color(0xFF3B5BDB),
                          child: Text(
                            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          player.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: isEliminated ? const Color(0xFF6B7280) : Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Role Guesses
          if (_hitmanTargets.isNotEmpty) ...[
            Text(
              'Select Roles for your targets:',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoleDropdown(
              label: 'Target 1 (${_getName(controller, _hitmanTargets[0])})',
              value: _hitmanRoleGuess1,
              onChanged: canVote ? (val) => setState(() => _hitmanRoleGuess1 = val) : null,
            ),
            const SizedBox(height: 12),
            if (_hitmanTargets.length > 1)
              _buildRoleDropdown(
                label: 'Target 2 (${_getName(controller, _hitmanTargets[1])})',
                value: _hitmanRoleGuess2,
                onChanged: canVote ? (val) => setState(() => _hitmanRoleGuess2 = val) : null,
              ),
          ],
        ],
      ),
    );
  }

  String _getName(GameController controller, String uid) {
    try {
      return controller.players.firstWhere((p) => p.userId == uid).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  Widget _buildRoleDropdown({required String label, required String? value, required ValueChanged<String?>? onChanged}) {
    // Exclude COP from valid hitman targets based on design spec! 
    final roles = ['DOCTOR', 'NURSE', 'REPORTER', 'BOUNTY_HUNTER', 'PROPHET', 'CITIZEN'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Inter')),
          isExpanded: true,
          dropdownColor: const Color(0xFF1C2333),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          onChanged: onChanged,
          items: roles.map((r) {
            return DropdownMenuItem<String>(
              value: r,
              child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter')),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── HITMAN STRIKE OVERLAY ────────────────────────────────────────────────────

class _HitmanStrikeOverlay extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<dynamic> players; // List<PlayerModel>
  final VoidCallback onDismiss;

  const _HitmanStrikeOverlay({
    required this.data,
    required this.players,
    required this.onDismiss,
  });

  @override
  State<_HitmanStrikeOverlay> createState() => _HitmanStrikeOverlayState();
}

class _HitmanStrikeOverlayState extends State<_HitmanStrikeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    // Auto-dismiss after 4s
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deaths = (widget.data['deaths'] as List<dynamic>? ?? []);
    final hitmanMetMafia = widget.data['hitmanMetMafia'] as bool? ?? false;

    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: const Color(0xFF0D121B).withOpacity(0.95),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 16),
                  const Text(
                    'HITMAN STRIKE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      letterSpacing: 3,
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (hitmanMetMafia)
                    _strikeNote('⚡ The Hitman has aligned with the Mafia team.')
                  else if (deaths.isEmpty)
                    _strikeNote("The Hitman's contract failed this round.")
                  else
                    ...deaths.map((d) {
                      final uid = d['userId'] as String? ?? '';
                      String name = 'Unknown';
                      try {
                        final p = widget.players
                            .firstWhere((p) => p.userId == uid);
                        name = p.name ?? 'Unknown';
                      } catch (_) {}
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF991B1B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF6B00).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('💀',
                                style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Eliminated by the Hitman',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: const Color(0xFFFF6B00)
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  Text(
                    'Tap to dismiss',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _strikeNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}
