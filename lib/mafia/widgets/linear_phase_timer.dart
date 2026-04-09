import 'dart:async';
import 'package:flutter/material.dart';

/// Compact linear progress bar countdown timer.
///
/// The bar starts FULL and smoothly depletes to empty as time runs out.
/// Color transitions: blue → amber → red as time runs low.
///
/// Always pass a stable absolute [endTime] (e.g. [GameController.phaseEndsAt])
/// rather than recomputing [DateTime.now().add(...)] on every build.
/// Recomputing each build produces a new [DateTime] object every second,
/// which triggers [didUpdateWidget] and restarts the animation — causing the
/// left-to-right glitch. A stable reference means the animation only resets
/// when the server genuinely changes the phase end-time (e.g. a +/- vote).
class LinearPhaseTimer extends StatefulWidget {
  final DateTime endTime;
  final double height;
  final TextStyle? textStyle;

  const LinearPhaseTimer({
    super.key,
    required this.endTime,
    this.height = 32,
    this.textStyle,
  });

  @override
  State<LinearPhaseTimer> createState() => _LinearPhaseTimerState();
}

class _LinearPhaseTimerState extends State<LinearPhaseTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _tickTimer;
  int _secondsLeft = 0;

  // ── helpers ────────────────────────────────────────────────────────────────

  int _calcRemaining(DateTime end) =>
      end.difference(DateTime.now()).inSeconds.clamp(0, 9999);

  /// Starts a 1-second periodic ticker that keeps [_secondsLeft] in sync
  /// with wall-clock time so the label is always accurate.
  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = _calcRemaining(widget.endTime);
      setState(() => _secondsLeft = s);
      if (s <= 0) _tickTimer?.cancel();
    });
  }

  /// Resets the animation controller for a new [endTime] and starts it.
  void _resetAnimation(DateTime end) {
    _controller.stop();
    final remaining = _calcRemaining(end);
    _secondsLeft = remaining;
    // AnimationController goes 0 -> 1 over [remaining] seconds.
    // We display  1 - value  so the bar starts FULL and depletes to EMPTY.
    _controller.duration = Duration(seconds: remaining == 0 ? 1 : remaining);
    _controller.forward(from: 0.0);
  }

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _secondsLeft = _calcRemaining(widget.endTime);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsLeft == 0 ? 1 : _secondsLeft),
    )..forward(from: 0.0);
    _startTick();
  }

  @override
  void didUpdateWidget(LinearPhaseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only restart when the absolute end-time genuinely changed.
    // A tolerance of >=2 s filters out trivial DateTime.now().add(...)
    // drift if the caller ever falls back to that pattern.
    final drift = widget.endTime.difference(oldWidget.endTime).inSeconds.abs();
    if (drift >= 2) {
      _resetAnimation(widget.endTime);
      _startTick();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── color ──────────────────────────────────────────────────────────────────

  Color _barColor() {
    if (_secondsLeft > 10) return const Color(0xFF135BEC); // blue
    if (_secondsLeft > 5) return const Color(0xFFEAB308); // amber
    return const Color(0xFFEF4444); // red
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // _controller.value: 0.0 (start) -> 1.0 (end of phase)
        // Invert so the bar is FULL at start and EMPTY at end.
        final progress = (1.0 - _controller.value).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_secondsLeft s',
              style:
                  widget.textStyle ??
                  const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: widget.height,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(_barColor()),
              ),
            ),
          ],
        );
      },
    );
  }
}
