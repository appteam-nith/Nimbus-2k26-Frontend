import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';

/// Listens to [GameController.pendingBroadcast] and shows a full-screen
/// BREAKING NEWS overlay whenever a reporter broadcast arrives.
///
/// Wrap this around screen content that might receive broadcasts:
///
/// ```dart
/// ReporterBroadcastListener(
///   child: NightScreen(),
/// )
/// ```
///
/// The overlay auto-dismisses after 5 s or on tap.
class ReporterBroadcastListener extends StatefulWidget {
  final Widget child;
  const ReporterBroadcastListener({super.key, required this.child});

  @override
  State<ReporterBroadcastListener> createState() =>
      _ReporterBroadcastListenerState();
}

class _ReporterBroadcastListenerState extends State<ReporterBroadcastListener> {
  OverlayEntry? _overlayEntry;
  ReporterBroadcast? _lastBroadcast;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gc = context.watch<GameController>();
    final pending = gc.pendingBroadcast;

    if (pending != null && pending != _lastBroadcast) {
      _lastBroadcast = pending;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOverlay(pending);
      });
    }
  }

  void _showOverlay(ReporterBroadcast broadcast) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _ReporterBroadcastOverlay(
        broadcast: broadcast,
        onDismiss: _dismiss,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismiss() {
    _removeOverlay();
    if (mounted) {
      context.read<GameController>().dismissBroadcast();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final gc = context.read<GameController>();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161D2B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Leave Game?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            content: const Text(
              'Are you sure you want to leave the game in progress?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                child: const Text('Leave', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await gc.leaveGame();
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: widget.child,
    );
  }
}

// ─── OVERLAY WIDGET ───────────────────────────────────────────────────────────

class _ReporterBroadcastOverlay extends StatefulWidget {
  final ReporterBroadcast broadcast;
  final VoidCallback onDismiss;

  const _ReporterBroadcastOverlay({
    required this.broadcast,
    required this.onDismiss,
  });

  @override
  State<_ReporterBroadcastOverlay> createState() =>
      _ReporterBroadcastOverlayState();
}

class _ReporterBroadcastOverlayState extends State<_ReporterBroadcastOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _pulseController;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterFade;
  late final Animation<double> _exitFade;
  late final Animation<double> _pulseAnim;

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _enterScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutBack),
    );
    _enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _enterController.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 5), _handleDismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _enterController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    _autoDismissTimer?.cancel();
    await _exitController.forward();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final broadcast = widget.broadcast;
    final roleColor = _roleColor(broadcast.role);

    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _exitController]),
      builder: (context, _) {
        final opacity =
            (_enterFade.value * _exitFade.value).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: _handleDismiss,
            child: Container(
              color: Colors.black.withOpacity(0.82),
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: _enterScale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _buildCard(broadcast, roleColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(ReporterBroadcast broadcast, Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F2E), Color(0xFF0D121B)],
        ),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Red Breaking News banner ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFCC0000),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => Opacity(
                opacity: _pulseAnim.value,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📰', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Text(
                      'BREAKING NEWS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('📰', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              children: [
                Text(
                  broadcast.playerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'has been identified as the',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 14),

                // Role chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: roleColor.withOpacity(0.55), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: roleColor.withOpacity(0.25),
                          blurRadius: 20)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _roleEmoji(broadcast.role),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        broadcast.role.displayName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Tap anywhere to dismiss',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(GameRole role) {
    switch (role) {
      case GameRole.MAFIA:
        return const Color(0xFFEF4444);
      case GameRole.DOCTOR:
        return const Color(0xFF22C55E);
      case GameRole.NURSE:
        return const Color(0xFF34D399);
      case GameRole.COP:
        return const Color(0xFF3B82F6);
      case GameRole.CITIZEN:
        return const Color(0xFF9CA3AF);
      case GameRole.HITMAN:
        return const Color(0xFFF97316);
      case GameRole.BOUNTY_HUNTER:
        return const Color(0xFFF59E0B);
      case GameRole.PROPHET:
        return const Color(0xFFA855F7);
      case GameRole.REPORTER:
        return const Color(0xFF06B6D4);
    }
  }

  String _roleEmoji(GameRole role) {
    switch (role) {
      case GameRole.MAFIA:
        return '🔫';
      case GameRole.DOCTOR:
        return '💉';
      case GameRole.NURSE:
        return '🩺';
      case GameRole.COP:
        return '🔍';
      case GameRole.CITIZEN:
        return '👤';
      case GameRole.HITMAN:
        return '🗡️';
      case GameRole.BOUNTY_HUNTER:
        return '🎯';
      case GameRole.PROPHET:
        return '🔮';
      case GameRole.REPORTER:
        return '📰';
    }
  }
}
