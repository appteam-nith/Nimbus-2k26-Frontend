import 'package:flutter/material.dart';
import '../models/club_models.dart';
import 'club_showcase_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Clubs List Screen  (Dep-clubs frame in Figma)
// ─────────────────────────────────────────────────────────────────────────────

class ClubsListScreen extends StatefulWidget {
  const ClubsListScreen({super.key});

  @override
  State<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends State<ClubsListScreen> {
  Department _selected = Department.all;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<Club> get _filtered {
    final clubs = kSampleClubs;
    return clubs.where((c) {
      final matchDept = _selected == Department.all || c.department == _selected;
      final matchQuery = _query.isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.department.fullName.toLowerCase().contains(_query.toLowerCase());
      return matchDept && matchQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _ClubsHeader(),

            // ── Search bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),

            // ── Filter chips ─────────────────────────────────────────
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Department.all,
                  Department.cse,
                  Department.ece,
                  Department.mech,
                  Department.civil,
                  Department.arch,
                  Department.chem,
                  Department.ee,
                ].map((d) => _FilterChip(
                      label: d.label,
                      active: d == _selected,
                      onTap: () => setState(() => _selected = d),
                    )).toList(),
              ),
            ),

            // ── List ─────────────────────────────────────────────────
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _ClubCard(
                  club: _filtered[i],
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ClubShowcaseScreen(club: _filtered[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────────────────────────────────────

class _ClubsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xF2F6F6F8),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Departmental Clubs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          _IconBtn(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 1, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x00000000), spreadRadius: 1),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF0F172A),
        ),
        decoration: const InputDecoration(
          hintText: 'Search clubs by name or dept',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF135BEC) : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: active
              ? const [
                  BoxShadow(
                      color: Color(0x4D135BEC),
                      blurRadius: 6,
                      offset: Offset(0, 4)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Club card  (matches Component2 in Figma)
// ─────────────────────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final Club club;
  final VoidCallback onTap;

  const _ClubCard({required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 64, height: 64,
                color: const Color(0xFFF1F5F9),
                child: club.imageUrl != null
                    ? Image.network(club.imageUrl!, fit: BoxFit.cover)
                    : _ClubPlaceholderIcon(department: club.department),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Department badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: club.department.badgeBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: club.department.badgeText.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                club.department.fullName,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: club.department.badgeText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    club.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple coloured icon placeholder when no image URL is present
class _ClubPlaceholderIcon extends StatelessWidget {
  final Department department;

  const _ClubPlaceholderIcon({required this.department});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            department.badgeText.withOpacity(0.7),
            department.badgeText,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          department.label[0],
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
