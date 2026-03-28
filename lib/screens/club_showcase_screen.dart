import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/club_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Club Showcase Screen
//  Opens when the user taps a club card on the Dep-clubs list screen.
// ─────────────────────────────────────────────────────────────────────────────

class ClubShowcaseScreen extends StatefulWidget {
  final Club club;

  const ClubShowcaseScreen({super.key, required this.club});

  @override
  State<ClubShowcaseScreen> createState() => _ClubShowcaseScreenState();
}

class _ClubShowcaseScreenState extends State<ClubShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  Club get club => widget.club;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          // ── Sliver app bar with hero banner ─────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF135BEC),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(ctx),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleBtn(
                  icon: Icons.ios_share_outlined,
                  onTap: () {
                    // TODO: share club
                  },
                ),
              ),
            ],
            title: Text(
              club.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeroBanner(club: club),
            ),
          ),

          // ── Sticky tab bar ───────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF135BEC),
                unselectedLabelColor: const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFF135BEC),
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Projects'),
                  Tab(text: 'Achievements'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ],

        // ── Tab body ─────────────────────────────────────────────────
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _ProjectsTab(club: club),
            _AchievementsTab(club: club),
            _AboutTab(club: club),
          ],
        ),
      ),

      // ── Bottom CTA ───────────────────────────────────────────────────
      bottomNavigationBar: _JoinBar(club: club),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero banner
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final Club club;

  const _HeroBanner({required this.club});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B3DB8), Color(0xFF1A7AE8)],
            ),
          ),
        ),

        // Decorative circles
        Positioned(
          right: -60, top: -40,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          left: -30, bottom: -20,
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 90, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Club logo + name row
              Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: club.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              club.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              club.department.label[0],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          club.department.fullName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _StatPill(value: '${club.memberCount}', label: 'Members'),
                  const SizedBox(width: 10),
                  _StatPill(value: '${club.projects.length}', label: 'Projects'),
                  const SizedBox(width: 10),
                  _StatPill(value: '${club.foundedYear}', label: 'Founded'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;

  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Projects tab
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectsTab extends StatelessWidget {
  final Club club;

  const _ProjectsTab({required this.club});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: club.projects.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ProjectCard(project: club.projects[i]),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ClubProject project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: project.status.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            project.status.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: project.status.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tech stack tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF135BEC).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        project.techStack,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: Color(0xFF135BEC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      project.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Divider
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 1),

                    // Footer row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            '${project.stars}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            '${project.year}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          if (project.repoUrl != null)
                            GestureDetector(
                              onTap: () {
                                // TODO: launch URL
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF135BEC),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 13, color: Color(0xFF135BEC)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
//  Achievements tab
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  final Club club;

  const _AchievementsTab({required this.club});

  @override
  Widget build(BuildContext context) {
    if (club.achievements.isEmpty) {
      return const Center(
        child: Text(
          'No achievements yet 🤞',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: club.achievements.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _AchievementCard(achievement: club.achievements[i]),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final ClubAchievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              achievement.icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  About tab
// ─────────────────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final Club club;

  const _AboutTab({required this.club});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutSection(
            title: 'About the Club',
            child: Text(
              club.description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            title: 'Quick Facts',
            child: Column(
              children: [
                _FactRow(icon: Icons.group_outlined,
                    label: 'Members', value: '${club.memberCount}'),
                _FactRow(icon: Icons.folder_copy_outlined,
                    label: 'Projects', value: '${club.projects.length}'),
                _FactRow(icon: Icons.calendar_today_outlined,
                    label: 'Founded', value: '${club.foundedYear}'),
                _FactRow(icon: Icons.school_outlined,
                    label: 'Department', value: club.department.fullName),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            title: 'Tech Stack',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allTech(club).map((t) => _TechChip(label: t)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _allTech(Club c) {
    final Set<String> tags = {};
    for (final p in c.projects) {
      for (final t in p.techStack.split('·')) {
        tags.add(t.trim());
      }
    }
    return tags.toList();
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _AboutSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              )),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              )),
        ],
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;

  const _TechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF135BEC).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Color(0xFF135BEC),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Join bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _JoinBar extends StatelessWidget {
  final Club club;

  const _JoinBar({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D135BEC),
                blurRadius: 15,
                offset: Offset(0, 10),
                spreadRadius: -3,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // TODO: Apply to join / show form
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _JoinSheet(club: club),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Apply to Join',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Join bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _JoinSheet extends StatelessWidget {
  final Club club;

  const _JoinSheet({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Apply to join ${club.name}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill in your details and the club coordinator will get back to you.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _SheetField(label: 'Full Name', placeholder: 'Your full name'),
          const SizedBox(height: 12),
          _SheetField(label: 'Roll Number', placeholder: 'e.g. CS21B1234'),
          const SizedBox(height: 12),
          _SheetField(
            label: 'Why do you want to join?',
            placeholder: 'Tell us briefly...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Submit Application',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final String placeholder;
  final int maxLines;

  const _SheetField({
    required this.label,
    required this.placeholder,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF374151),
            )),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF135BEC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SliverPersistentHeaderDelegate for the tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
