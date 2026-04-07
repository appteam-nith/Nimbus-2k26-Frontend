import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models/club_models.dart';

class ClubCard extends StatefulWidget {
  final String title;
  final String department;
  final Color departmentColor;
  final String description;
  final String imagePath;
  final String clubId; // used to find the matching Club from kSampleClubs

  const ClubCard({
    super.key,
    required this.title,
    required this.department,
    required this.departmentColor,
    required this.description,
    required this.imagePath,
    required this.clubId,
  });

  @override
  State<ClubCard> createState() => _ClubCardState();
}

class _ClubCardState extends State<ClubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _expanded = false;

  Club? get _club => kSampleClubs.cast<Club?>().firstWhere(
        (c) => c!.id == widget.clubId,
        orElse: () => null,
      );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = _club;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () => setState(() => _expanded = !_expanded),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _expanded ? 0.13 : 0.07),
                blurRadius: _expanded ? 24 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header (always visible) ────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Club logo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.backgroundDark,
                        image: DecorationImage(
                          image: AssetImage(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + department badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.departmentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.department,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Description (always visible)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  widget.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ),

              // ── Expanded section ────────────────────────────────────
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: club != null
                    ? _ExpandedContent(club: club)
                    : const SizedBox.shrink(),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Expanded content shown inside the card
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandedContent extends StatefulWidget {
  final Club club;

  const _ExpandedContent({required this.club});

  @override
  State<_ExpandedContent> createState() => _ExpandedContentState();
}

class _ExpandedContentState extends State<_ExpandedContent> {
  int _selectedTab = 0; // 0 = Projects, 1 = Achievements, 2 = About

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _StatBadge(
                  icon: Icons.group_outlined,
                  label: '${widget.club.memberCount} Members'),
              const SizedBox(width: 10),
              _StatBadge(
                  icon: Icons.folder_copy_outlined,
                  label: '${widget.club.projects.length} Projects'),
              const SizedBox(width: 10),
              _StatBadge(
                  icon: Icons.calendar_today_outlined,
                  label: 'Est. ${widget.club.foundedYear}'),
            ],
          ),
        ),

        // Tab selector
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              _TabChip(
                  label: 'Projects',
                  active: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0)),
              const SizedBox(width: 8),
              _TabChip(
                  label: 'Achievements',
                  active: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1)),
              const SizedBox(width: 8),
              _TabChip(
                  label: 'About',
                  active: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2)),
            ],
          ),
        ),

        // Tab content
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: _buildTabContent(),
        ),

        // Apply to Join button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _showJoinSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                'Apply to Join',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _ProjectsList(club: widget.club);
      case 1:
        return _AchievementsList(club: widget.club);
      case 2:
        return _AboutSection(club: widget.club);
      default:
        return const SizedBox.shrink();
    }
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinSheet(club: widget.club),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Projects list
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectsList extends StatelessWidget {
  final Club club;

  const _ProjectsList({required this.club});

  @override
  Widget build(BuildContext context) {
    if (club.projects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No projects yet 🚀',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF94A3B8))),
        ),
      );
    }
    return Column(
      children: club.projects
          .map((p) => _ProjectTile(project: p))
          .toList(),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ClubProject project;

  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: project.status.bg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  project.status.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: project.status.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            project.techStack,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF135BEC),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            project.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 3),
              Text('${project.stars}',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B))),
              const SizedBox(width: 10),
              const Icon(Icons.calendar_today_outlined,
                  size: 11, color: Color(0xFF94A3B8)),
              const SizedBox(width: 3),
              Text('${project.year}',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Achievements list
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementsList extends StatelessWidget {
  final Club club;

  const _AchievementsList({required this.club});

  @override
  Widget build(BuildContext context) {
    if (club.achievements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No achievements yet 🤞',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF94A3B8))),
        ),
      );
    }
    return Column(
      children: club.achievements
          .map((a) => _AchievementTile(achievement: a))
          .toList(),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final ClubAchievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(achievement.icon,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
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
//  About section
// ─────────────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final Club club;

  const _AboutSection({required this.club});

  @override
  Widget build(BuildContext context) {
    final techs = _allTech(club);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.55,
            ),
          ),
          if (techs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            const Text(
              'TECH STACK',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: techs
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF135BEC),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
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

// ─────────────────────────────────────────────────────────────────────────────
//  Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              active ? const Color(0xFF135BEC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
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
              width: 36,
              height: 4,
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
          _SheetField(
              label: 'Roll Number', placeholder: 'e.g. CS21B1234'),
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
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
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