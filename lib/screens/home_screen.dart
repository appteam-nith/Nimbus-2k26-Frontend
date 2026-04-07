// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/top_performers.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // ── Mafia Game Banner ─────────────────────────────────────────
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
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF9D5EF5).withValues(alpha: 0.4)),
                      ),
                      child: const Center(
                        child: Text('🎭',
                            style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nimbus Mafia',
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
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF9D5EF5), size: 14),
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
            const EventCard(
              title: "AI & Future Tech",
              tag: "Workshop",
              time: "10:00",
              location: "Lecture Hall A",
              image: "assets/images/event1.png",
              primary: true,
            ),
            EventCard(
              title: "RoboWars Qualifiers",
              tag: "Competition",
              time: "13:00",
              location: "Main Ground",
              image: "assets/images/event2.png",
            ),
            EventCard(
              title: "CyberSec Seminar",
              tag: "Talk",
              time: "15:00",
              location: "Lab 2",
              image: "assets/images/event3.png",
            ),
          ],
        ),
      ),
    );
  }
}
