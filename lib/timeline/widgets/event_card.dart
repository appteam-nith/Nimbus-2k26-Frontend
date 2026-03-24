import 'package:flutter/material.dart';
import '../models/timeline_event.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  const TimelineEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================
          // DOT ONLY (line is in screen)
          // =========================
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 19,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: event.isLive ? 16 : 15,
                    height: event.isLive ? 16 : 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.isLive
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFF0F4F8), // matches screen bg
                      border: event.isLive
                          ? null
                          : Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 2.4,
                            ),
                      boxShadow: event.isLive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.6),
                                blurRadius: 5,
                                spreadRadius: 1.8,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // =========================
          // CARD AREA
          // =========================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: event.isLive
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFDCEAFD)],
                        )
                      : null,
                  color: event.isLive ? null : Colors.white,
                  boxShadow: event.isLive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: event.isLive
                        ? const BorderSide(
                            color: Color(0xFF60A5FA),
                            width: 1.4,
                          )
                        : const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 0.5,
                          ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: event.isLive ? 26 : 6),
                            Padding(
                              padding: const EdgeInsets.only(right: 75),
                              child: Text(
                                event.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontSize: event.isLive ? 20 : 16,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: event.isLive ? 15.5 : 14,
                                    color: const Color(0xFF64748B),
                                  ),
                            ),
                            SizedBox(height: event.isLive ? 12 : 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/location.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF3B82F6),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.location,
                                  style: TextStyle(
                                    fontSize: event.isLive ? 14.5 : 13.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // =========================
                        // LIVE badge
                        // =========================
                        if (event.isLive)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color.fromARGB(255, 245, 223, 221),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 241, 129, 121),
                                  width: 1.2,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // =========================
                        // TIME
                        // =========================
                        Positioned(
                          top: 2,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: event.isLive
                                  ? const Color(0xFFBFDBFE)
                                  : const Color(0xFFEFF6FF),
                            ),
                            child: Text(
                              _formatTime(event.startTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final suffix = isPm ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}