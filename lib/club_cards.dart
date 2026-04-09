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

class _ExpandedContent extends StatelessWidget {
  final Club club;

  const _ExpandedContent({required this.club});

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
                  label: '${club.memberCount} Members'),
              const SizedBox(width: 10),
              _StatBadge(
                  icon: Icons.calendar_today_outlined,
                  label: 'Est. ${club.foundedYear}'),
            ],
          ),
        ),

        // Section header for "About"
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Text(
            'ABOUT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),

        // About content
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: _AboutSection(club: club),
        ),
      ],
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