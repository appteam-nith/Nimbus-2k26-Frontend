import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'club_cards.dart';

class DepartmentalClubsPage extends StatefulWidget {
  const DepartmentalClubsPage({super.key});

  @override
  State<DepartmentalClubsPage> createState() => _DepartmentalClubsPageState();
}

class _DepartmentalClubsPageState extends State<DepartmentalClubsPage> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  int _selectedFilterIndex = 0;

  final List<String> filters = [
    'All',
    'CSE',
    'ECE',
    'Mech',
    'Civil',
    'Electrical',
    'Chem',
    'Arch',
    'MNC',
    'Physics',
    'Material'
  ];

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
          'Departmental Clubs',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchBar(),
            const SizedBox(height: 12),
            _filterChips(),
            const SizedBox(height: 16),
            Expanded(child: _clubList()),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search clubs by name or dept',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
        ),
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

  Widget _filterChips() {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == _selectedFilterIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          color: AppColors.primaryBlue.withOpacity(0.2),
          child: AnimatedAlign(
            alignment: Alignment.lerp(
              Alignment.topLeft,
              Alignment.topRight,
              _selectedFilterIndex / (filters.length - 1),
            )!,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getAllClubs() {
    return [
      {
        'title': 'Team .EXE',
        'department': 'Computer Science ',
        'departmentColor': const Color(0xFFEEF5FF),
        'description':
            'The official technical club of CSE, focusing on web dev, competitive coding, and open source.',
        'imagePath': 'assets/clubs/EXE.jpg',
        'filterKey': 'CSE',
      },
      {
        'title': 'Hermetica',
        'department': 'Chemical ',
        'departmentColor': const Color(0xFFF0FBEF),
        'description':
            'Innovating in process design and sustainable chemical solutions for the future.',
        'imagePath': 'assets/clubs/Hermetica.jpg',
        'filterKey': 'Chem',
      },
      {
        'title': 'Vibhav',
        'department': 'Electronics & Communication',
        'departmentColor': const Color(0xFFFFF9ED),
        'description':
            'Exploring embedded systems, VLSI, and signal processing.',
        'imagePath': 'assets/clubs/Vibhav.jpg',
        'filterKey': 'ECE',
      },
      {
        'title': 'Ojas',
        'department': 'Electrical ',
        'departmentColor': const Color.fromARGB(248, 224, 255, 247),
        'description':
            'Lighting up the campus with innovation in power systems and renewable energy.',
        'imagePath': 'assets/clubs/Ojas.jpg',
        'filterKey': 'Electrical',
      },
      {
        'title': 'Medextrous',
        'department': 'Mechanical ',
        'departmentColor': const Color.fromARGB(255, 240, 200, 200),
        'description':
            'Designing and manufacturing the machines of tomorrow.',
        'imagePath': 'assets/clubs/Medextrous.jpg',
        'filterKey': 'Mech',
      },
      {
        'title': 'C-Helix',
        'department': 'Civil ',
        'departmentColor': const Color.fromARGB(255, 220, 190, 240),
        'description':
            'Exploring infrastructure, structural design, and sustainable civil engineering projects.',
        'imagePath': 'assets/clubs/CHelix.jpg',
        'filterKey': 'Civil',
      },
      {
        'title': 'Matcom',
        'department': 'Mathematics & Computing',
        'departmentColor': const Color(0xFFEEF5FF),
        'description':
            'Bridging mathematics and computation through algorithms, data science, and theoretical computing.',
        'imagePath': 'assets/clubs/Matcom.jpg',
        'filterKey': 'MNC',
      },
      {
        'title': 'Metamorph',
        'department': 'Materials Science',
        'departmentColor': const Color.fromARGB(255, 240, 245, 180),
        'description':
            'Transforming materials science through research, innovation, and advanced material applications.',
        'imagePath': 'assets/clubs/Metamorph.jpg',
        'filterKey': 'Material',
      },
      {
        'title': 'Design O Crafts',
        'department': 'Architecture',
        'departmentColor': const Color.fromARGB(255, 242, 200, 240),
        'description':
            'Creating innovative architectural designs and sustainable urban planning solutions.',
        'imagePath': 'assets/clubs/DesignOCrafts.jpg',
        'filterKey': 'Arch',
      },
      {
        'title': 'Team Abraxas',
        'department': 'Physics ',
        'departmentColor': const Color.fromARGB(255, 200, 235, 210),
        'description':
            'Exploring quantum mechanics, astrophysics, and experimental physics research.',
        'imagePath': 'assets/clubs/Abraxas.jpg',
        'filterKey': 'Physics',
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredClubs() {
    final allClubs = _getAllClubs();
    return allClubs.where((club) {
      final matchesSearch = _searchQuery.isEmpty ||
          club['title'].toLowerCase().contains(_searchQuery) ||
          club['department'].toLowerCase().contains(_searchQuery) ||
          club['description'].toLowerCase().contains(_searchQuery);

      final matchesFilter = _selectedFilterIndex == 0 ||
          club['filterKey'] == filters[_selectedFilterIndex];

      return matchesSearch && matchesFilter;
    }).toList();
  }

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
          .map((club) => ClubCard(
                title: club['title'],
                department: club['department'],
                departmentColor: club['departmentColor'],
                description: club['description'],
                imagePath: club['imagePath'],
              ))
          .toList(),
    );
  }


}