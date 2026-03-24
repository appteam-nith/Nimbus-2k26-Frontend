import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'core_club_card.dart';

class CoreClubsPage extends StatefulWidget {
  const CoreClubsPage({super.key});

  @override
  State<CoreClubsPage> createState() => _CoreClubsPageState();
}

class _CoreClubsPageState extends State<CoreClubsPage> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Core Clubs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchBar(),
            const SizedBox(height: 16),
            Expanded(child: _clubList()),
          ],
        ),
      ),
    );
  }

  /// 🔍 Search Bar
  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search core clubs',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// 📋 Club List
  List<Map<String, String>> _getAllClubs() {
    return [
      {
        'title': 'Team Public Relation',
        'description':
            'Handles outreach, communication, branding, and public engagement for all Nimbus events.',
        'imagePath': 'assets/clubs/PR.jpg',
      },
      {
        'title': 'App Team',
        'description':
            'Develops and maintains the Hillfair and Nimbus app, organizes HackOnHills .',
        'imagePath': 'assets/clubs/AppTeam.jpg',
      },
      {
        'title': 'Pixonoids',
        'description':
            'For people with passion for photography, videography, and creative visual content.',
        'imagePath': 'assets/clubs/Pixonoids.jpg',
      },
      {
        'title': 'Resurgance',
        'description':
            'Dedicated to gaming, esports, and interactive entertainment experiences.',
        'imagePath': 'assets/clubs/Resurgance.jpg',
      },
      {
        'title': 'Team Finance and Treasury',
        'description':
            'Manages budgeting, finances, and sponsorships for all Nimbus events.',
        'imagePath': 'assets/clubs/TFT.jpg',
      },
      {
        'title': 'Design And Deco',
        'description':
            'Creates props, decorations, and handles all the technical setup for Nimbus events.',
        'imagePath': 'assets/clubs/DesignNDeco.jpg',
      },
    ];
  }

  List<Map<String, String>> _getFilteredClubs() {
    final allClubs = _getAllClubs();
    if (_searchQuery.isEmpty) {
      return allClubs;
    }
    return allClubs
        .where((club) =>
            club['title']!.toLowerCase().contains(_searchQuery) ||
            club['description']!.toLowerCase().contains(_searchQuery))
        .toList();
  }

  /// 📋 Club List
  Widget _clubList() {
    final filteredClubs = _getFilteredClubs();

    if (filteredClubs.isEmpty) {
      return Center(
        child: Text(
          'No clubs found',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView(
      children: filteredClubs
          .map((club) => CoreClubCard(
                title: club['title']!,
                description: club['description']!,
                imagePath: club['imagePath']!,
              ))
          .toList(),
    );
  }


}

// CoreClubCard is now provided by lib/core_club_card.dart