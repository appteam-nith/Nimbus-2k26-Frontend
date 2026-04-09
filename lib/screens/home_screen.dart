// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import '../widgets/nimbus_city_logo.dart';
import 'package:provider/provider.dart';
import '../widgets/header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/top_performers.dart';
import '../widgets/event_card.dart';
import '../timeline/controller/timeline_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = context.read<TimelineController>().loadTimeline();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const HeaderWidget(),
            const SizedBox(height: 16),
            const SearchBarWidget(),
            const SizedBox(height: 24),
            const TopPerformers(),
            const SizedBox(height: 20),
            // ── Mafia Game Banner ─────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/mafia/lobby'),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D0B1E),
                      Color(0xFF1E1040),
                      Color(0xFF2D1A5E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const NimbusCityLogo(size: 54),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nimbus City',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Play with friends • 5 / 8 / 12 players',
                            style: TextStyle(
                              color: Color(0xFF9D5EF5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF9D5EF5),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Upcoming Events",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<void>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                final controller = context.watch<TimelineController>();
                final events = controller.upcomingEvents;

                if (snapshot.connectionState == ConnectionState.waiting &&
                    events.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.error != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      controller.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No upcoming events available.'),
                  );
                }

                return Column(
                  children: events.take(3).map((event) {
                    return EventCard(
                      title: event.title,
                      tag: event.isLive ? 'Live' : 'Event',
                      time: _formatTime(event.startTime),
                      location: event.location,
                      image: event.imageUrl.isNotEmpty
                          ? event.imageUrl
                          : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
                      primary: event.isLive,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
