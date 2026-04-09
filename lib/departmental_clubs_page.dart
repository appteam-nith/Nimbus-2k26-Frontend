import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'club_cards.dart';
import 'models/club_models.dart';

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
    'Material',
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
        foregroundColor: AppColors.dark,
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
          ),
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
        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14),
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
            separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                      color: isSelected ? Colors.white : AppColors.dark,
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
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
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

  List<Club> _getFilteredClubs() {
    return kSampleClubs.where((club) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          club.name.toLowerCase().contains(_searchQuery) ||
          club.department.fullName.toLowerCase().contains(_searchQuery) ||
          club.description.toLowerCase().contains(_searchQuery);

      final matchesFilter =
          _selectedFilterIndex == 0 ||
          club.department.label == filters[_selectedFilterIndex];

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _clubList() {
    final filteredClubs = _getFilteredClubs();

    if (filteredClubs.isEmpty) {
      return Center(
        child: Text(
          'No clubs found',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredClubs.length,
      itemBuilder: (context, index) {
        final club = filteredClubs[index];
        return ClubCard(
          clubId: club.id,
          title: club.name,
          department: club.department.label,
          departmentColor: club.department.badgeBg,
          description: club.description,
          imagePath: club.imageAsset ?? 'assets/clubs/default.jpg',
        );
      },
    );
  }
}