// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/top_performers.dart';
import '../widgets/event_card.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNav(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HeaderWidget(),
          SizedBox(height: 16),
          SearchBarWidget(),
          SizedBox(height: 24),
          TopPerformers(),
          SizedBox(height: 24),
          Row(
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

          SizedBox(height: 12),
          EventCard(
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
    );
  }
}