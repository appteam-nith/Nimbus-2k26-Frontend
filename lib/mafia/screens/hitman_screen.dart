import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../services/game_api.dart';

// ─── HITMAN NIGHT ACTION SCREEN ───────────────────────────────────────────────
//
// The hitman selects exactly 2 targets and guesses each one's role.
// If BOTH guesses are correct, both targets are eliminated at T-5s.
// Uses vote_type = HITMAN_TARGET with target_meta = { targets, roles }.
//
// This screen is pushed from night_screen.dart for HITMAN role players.

class HitmanScreen extends StatefulWidget {
  const HitmanScreen({super.key});

  @override
  State<HitmanScreen> createState() => _HitmanScreenState();
}

class _HitmanScreenState extends State<HitmanScreen> {
  // Two-slot selection: index 0 = first pick, index 1 = second pick
  final List<PlayerModel?> _targets = [null, null];
  final List<String?> _roles = [null, null];

  int _activeSlot = 0; // which slot we're filling right now (0 or 1)
  bool _isSubmitting = false;
  String? _errorMsg;

  // -- Colours (dark red / hitman theme) ----------------------------------------
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF14141A);
  static const _card = Color(0xFF1C1C26);
  static const _red = Color(0xFFCF2020);
  static const _redGlow = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _textMuted = Color(0xFF6B7280);
  static const _textPrimary = Color(0xFFEEF2FF);

  // Valid role guesses the hitman can pick from (excluding COP — cannot target COP)
  static const _guessableRoles = [
    'MAFIA',
    'DOCTOR',
    'NURSE',
    'BOUNTY_HUNTER',
    'REPORTER',
    'PROPHET',
    'CITIZEN',
    'HITMAN',
  ];

  // ── Submit ──────────────────────────────────────────────────────────────────

  bool get _canSubmit =>
      _targets[0] != null &&
      _targets[1] != null &&
      _roles[0] != null &&
      _roles[1] != null &&
      !_isSubmitting;

  Future<void> _submit(GameController gc) async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      await GameApi.instance.submitVote(
        gc.roomCode!,
        'HITMAN_TARGET',
        targetMeta: {
          'targets': [_targets[0]!.userId, _targets[1]!.userId],
          'roles': [_roles[0]!, _roles[1]!],
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎯 Contract locked. Executing at T-5s.',
            style: TextStyle(fontFamily: 'Inter', color: Colors.white),
          ),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMsg = e
            .toString()
            .replaceFirst('GameApiException', '')
            .replaceAll(RegExp(r'^\(\d+\):\s*'), '');
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final candidates = gc.players
        .where((p) => p.isAlive && p.userId != gc.myUserId)
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(gc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // ── Contract slots ──────────────────────────────────────
                    _buildSectionLabel('CONTRACT TARGETS', 'Select 2 players'),
                    const SizedBox(height: 12),
                    _buildContractSlots(),
                    const SizedBox(height: 28),

                    // ── Player grid ─────────────────────────────────────────
                    _buildSectionLabel(
                      'SELECT TARGET ${_activeSlot + 1}',
                      _targets[_activeSlot] != null
                          ? 'Tap again to change'
                          : 'Tap a player below',
                    ),
                    const SizedBox(height: 12),
                    _buildPlayerGrid(candidates, gc.myUserId),
                    const SizedBox(height: 28),

                    _buildSectionLabel(
                      'QUICK PREDICTION',
                      'Role popup appears as soon as you tap a player',
                    ),
                    const SizedBox(height: 8),

                    // ── Error banner ─────────────────────────────────────────
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 8),
                      _buildErrorBanner(_errorMsg!),
                    ],
                    const SizedBox(height: 100), // bottom padding for button
                  ],
                ),
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────────────
            _buildActionBar(gc),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(GameController gc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: Color(0xFF2A0A0A), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C2C3C)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textMuted,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HITMAN CONTRACT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: _redGlow,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Night ${gc.round} · Select 2 targets + guess their roles',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: _textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Slot indicator
          _buildSlotDots(),
        ],
      ),
    );
  }

  Widget _buildSlotDots() {
    return Row(
      children: List.generate(2, (i) {
        final filled = _targets[i] != null;
        final active = _activeSlot == i && !filled;
        return Container(
          margin: const EdgeInsets.only(left: 6),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? _redGlow
                : active
                ? _redGlow.withValues(alpha: 0.3)
                : _card,
            border: Border.all(
              color: filled || active
                  ? _redGlow
                  : _textMuted.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  // ── Contract Slots ───────────────────────────────────────────────────────────

  Widget _buildContractSlots() {
    return Row(
      children: [
        Expanded(child: _buildSlot(0)),
        const SizedBox(width: 12),
        Expanded(child: _buildSlot(1)),
      ],
    );
  }

  Widget _buildSlot(int idx) {
    final player = _targets[idx];
    final role = _roles[idx];
    final isActive = _activeSlot == idx;

    return GestureDetector(
      onTap: () => setState(() => _activeSlot = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: player != null
              ? _red.withValues(alpha: 0.08)
              : isActive
              ? _redGlow.withValues(alpha: 0.05)
              : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: player != null
                ? _red.withValues(alpha: 0.6)
                : isActive
                ? _redGlow.withValues(alpha: 0.3)
                : const Color(0xFF2C2C3C),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: player == null
            ? Column(
                children: [
                  const Icon(Icons.add_rounded, color: _textMuted, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    'Target ${idx + 1}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _red.withValues(alpha: 0.3),
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: _textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _targets[idx] = null;
                          _roles[idx] = null;
                          _activeSlot = idx;
                        }),
                        child: const Icon(
                          Icons.close_rounded,
                          color: _textMuted,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  if (role != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: _amber,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 4),
                  Text(
                    role == null ? 'Tap a player to set role guess' : '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: _textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Player Grid ──────────────────────────────────────────────────────────────

  Future<String?> _showRolePredictionPopup(String playerName) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF151520),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _redGlow.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predict $playerName',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose your role guess for this target.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: _textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _guessableRoles
                      .map(
                        (role) => GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(role),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _amber.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Inter', color: _textMuted),
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

  Widget _buildPlayerGrid(List<PlayerModel> candidates, String? myUserId) {
    final selectedIds = _targets
        .where((t) => t != null)
        .map((t) => t!.userId)
        .toSet();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: candidates.length,
      itemBuilder: (context, i) {
        final p = candidates[i];
        final isSelected = selectedIds.contains(p.userId);
        final isSlot0 = _targets[0]?.userId == p.userId;
        final isSlot1 = _targets[1]?.userId == p.userId;
        final isEliminated = !p.isAlive;

        return GestureDetector(
          onTap: isEliminated
              ? null
              : () async {
                  setState(() {
                    if (isSelected) {
                      // Deselect
                      if (isSlot0) {
                        _targets[0] = null;
                        _roles[0] = null;
                        _activeSlot = 0;
                      } else if (isSlot1) {
                        _targets[1] = null;
                        _roles[1] = null;
                        _activeSlot = 1;
                      }
                    }
                  });
                  if (isSelected || !mounted) return;

                  final slot = _activeSlot;
                  final guessedRole = await _showRolePredictionPopup(p.name);
                  if (!mounted || guessedRole == null) return;

                  setState(() {
                    _targets[slot] = p;
                    _roles[slot] = guessedRole;
                    if (slot == 0 && _targets[1] == null) {
                      _activeSlot = 1;
                    } else if (slot == 1 && _targets[0] == null) {
                      _activeSlot = 0;
                    }
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? _red.withValues(alpha: 0.15)
                  : isEliminated
                  ? _card.withValues(alpha: 0.5)
                  : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? _redGlow
                    : isEliminated
                    ? const Color(0xFF2C2C3C).withValues(alpha: 0.5)
                    : const Color(0xFF2C2C3C),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isEliminated
                          ? const Color(0xFF374151)
                          : isSelected
                          ? _red.withValues(alpha: 0.5)
                          : const Color(0xFF3B5BDB),
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isEliminated
                              ? const Color(0xFF6B7280)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isEliminated)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                    // Slot badge
                    if (isSlot0 || isSlot1)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: _redGlow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isSlot0 ? '1' : '2',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isEliminated
                        ? const Color(0xFF6B7280)
                        : _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Role Slot Dropdown ───────────────────────────────────────────────────────

  Widget _buildRoleSlot(int idx, GameController gc) {
    final player = _targets[idx];
    if (player == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _roles[idx] != null
              ? _amber.withValues(alpha: 0.5)
              : const Color(0xFF2C2C3C),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roles[idx],
          hint: Text(
            'Guess role for ${player.name}',
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF1C1C26),
          iconEnabledColor: _textMuted,
          onChanged: (val) => setState(() => _roles[idx] = val),
          items: _guessableRoles
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── Action Bar ───────────────────────────────────────────────────────────────

  Widget _buildActionBar(GameController gc) {
    final ready = _canSubmit;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Color(0xFF2A0A0A))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar showing how complete the contract is
          _buildProgressBar(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: ready
                    ? const LinearGradient(
                        colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                      )
                    : null,
                color: ready ? null : const Color(0xFF2C2C3C),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: ready ? () => _submit(gc) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isSubmitting
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gavel_rounded,
                                color: ready ? Colors.white : _textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                ready ? 'EXECUTE CONTRACT' : _statusText(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ready ? Colors.white : _textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Skip / Abstain',
              style: TextStyle(
                fontFamily: 'Inter',
                color: _textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    if (_targets[0] == null) return 'SELECT TARGET 1';
    if (_targets[1] == null) return 'SELECT TARGET 2';
    if (_roles[0] == null) return 'GUESS ROLE FOR TARGET 1';
    if (_roles[1] == null) return 'GUESS ROLE FOR TARGET 2';
    return 'EXECUTE CONTRACT';
  }

  Widget _buildProgressBar() {
    final steps = [
      _targets[0] != null,
      _targets[1] != null,
      _roles[0] != null,
      _roles[1] != null,
    ];
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: steps[i] ? _redGlow : const Color(0xFF2C2C3C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: _textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: _textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _redGlow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _redGlow.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _redGlow, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: _redGlow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
