import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated circular countdown ring.
///
/// Receives [endTime] and ticks locally every second.
/// Color transitions from blue → amber → red as time runs low.
///
/// Usage:
/// ```dart
/// PhaseTimer(endTime: DateTime.now().add(const Duration(seconds: 30)))
/// ```
class PhaseTimer extends StatefulWidget {
  final DateTime endTime;
  final double size;
  final double strokeWidth;
  final TextStyle? textStyle;

  const PhaseTimer({
    super.key,
    required this.endTime,
    this.size = 80,
    this.strokeWidth = 6,
    this.textStyle,
  });

  @override
  State<PhaseTimer> createState() => _PhaseTimerState();
}

class _PhaseTimerState extends State<PhaseTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcController;
  late int _totalSeconds;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.endTime.difference(DateTime.now()).inSeconds.clamp(0, 999);
    _secondsLeft = _totalSeconds;

    _arcController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    )..forward();

    // Tick every second to update the number display
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _secondsLeft =
            widget.endTime.difference(DateTime.now()).inSeconds.clamp(0, 999);
      });
      if (_secondsLeft > 0) _tick();
    });
  }

  @override
  void didUpdateWidget(PhaseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _arcController.stop();
      _totalSeconds =
          widget.endTime.difference(DateTime.now()).inSeconds.clamp(0, 999);
      _secondsLeft = _totalSeconds;
      _arcController.duration = Duration(seconds: _totalSeconds);
      _arcController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  Color _ringColor() {
    if (_secondsLeft > 10) return const Color(0xFF135BEC); // brand blue
    if (_secondsLeft > 5) return const Color(0xFFEAB308); // amber
    return const Color(0xFFEF4444); // red
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _arcController,
        builder: (context, child) {
          final progress = _totalSeconds == 0
              ? 0.0
              : 1.0 - _arcController.value;
          return CustomPaint(
            painter: _RingPainter(
              progress: progress,
              color: _ringColor(),
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: (widget.textStyle ??
                        const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Colors.white,
                        ))
                    .copyWith(color: _ringColor()),
                child: Text('$_secondsLeft'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── RING PAINTER ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 → full, 1.0 → empty
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Background track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground arc
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start from top
      -2 * math.pi * progress, // sweep counter-clockwise as time drains
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
