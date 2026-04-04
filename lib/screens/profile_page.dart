import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ── Nimbus color tokens ──────────────────────────────────────────────────────
class NimbusColors {
  static const blue = Color(0xFF2D5BE3);
  static const blueLight = Color(0xFFEFF4FF);
  static const blueDark = Color(0xFF1A3BB3);
  static const gold = Color(0xFFF59E0B);
  static const goldLight = Color(0xFFFEF3C7);
  static const green = Color(0xFF10B981);
  static const greenLight = Color(0xFFECFDF5);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFF5F3FF);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFF7ED);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardBg = Color(0xFFF5F6FA);
}

// ── Data models ──────────────────────────────────────────────────────────────
class BadgeItem {
  final String emoji;
  final String label;
  final Color bg;
  const BadgeItem({required this.emoji, required this.label, required this.bg});
}

class RegisteredEvent {
  final String emoji;
  final Color thumbGradientStart;
  final Color thumbGradientEnd;
  final String name;
  final String meta;
  final String tag;
  final Color tagBg;
  final Color tagText;
  const RegisteredEvent({
    required this.emoji,
    required this.thumbGradientStart,
    required this.thumbGradientEnd,
    required this.name,
    required this.meta,
    required this.tag,
    required this.tagBg,
    required this.tagText,
  });
}

class PointsActivity {
  final String activity;
  final String date;
  final int points;
  const PointsActivity(
      {required this.activity, required this.date, required this.points});
}

// ── Profile Page ─────────────────────────────────────────────────────────────
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _badges = [
    BadgeItem(emoji: '🏅', label: 'Top Performer', bg: NimbusColors.goldLight),
    BadgeItem(emoji: '💻', label: 'Hackathon Pro', bg: NimbusColors.blueLight),
    BadgeItem(emoji: '🎤', label: 'Speaker', bg: NimbusColors.purpleLight),
    BadgeItem(emoji: '🌱', label: 'Early Bird', bg: NimbusColors.greenLight),
    BadgeItem(emoji: '🔥', label: 'On a Streak', bg: NimbusColors.orangeLight),
  ];

  static const _events = [
    RegisteredEvent(
      emoji: '🤖',
      thumbGradientStart: NimbusColors.blueDark,
      thumbGradientEnd: NimbusColors.blue,
      name: 'AI & Future Tech',
      meta: 'Oct 24 · Lecture Hall A',
      tag: 'Workshop',
      tagBg: NimbusColors.blueLight,
      tagText: NimbusColors.blue,
    ),
    RegisteredEvent(
      emoji: '⚔️',
      thumbGradientStart: Color(0xFF92400E),
      thumbGradientEnd: NimbusColors.gold,
      name: 'RoboWars Qualifiers',
      meta: 'Oct 24 · Main Ground',
      tag: 'Competitive',
      tagBg: NimbusColors.goldLight,
      tagText: Color(0xFF92400E),
    ),
    RegisteredEvent(
      emoji: '🔐',
      thumbGradientStart: Color(0xFF4C1D95),
      thumbGradientEnd: NimbusColors.purple,
      name: 'CyberSec Seminar',
      meta: 'Oct 25 · Lab 2',
      tag: 'Talk',
      tagBg: NimbusColors.purpleLight,
      tagText: NimbusColors.purple,
    ),
    RegisteredEvent(
      emoji: '💡',
      thumbGradientStart: NimbusColors.blueDark,
      thumbGradientEnd: NimbusColors.blue,
      name: 'Mega Hackathon 2024',
      meta: 'Oct 25 · CS Lab 1',
      tag: 'Hackathon',
      tagBg: NimbusColors.goldLight,
      tagText: Color(0xFF92400E),
    ),
  ];

  static const _pointsActivities = [
    PointsActivity(
        activity: 'Hackathon Finalist', date: 'Oct 24', points: 800),
    PointsActivity(
        activity: 'Workshop Attended', date: 'Oct 23', points: 150),
    PointsActivity(activity: 'Quiz Winner', date: 'Oct 22', points: 300),
    PointsActivity(activity: 'Event Cancelled', date: 'Oct 20', points: -50),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final displayName =
            auth.userName ?? user?.displayName ?? 'Nimbus User';
        final email = auth.userEmail ?? user?.email ?? '';
        final photoUrl = user?.photoURL;
        final handle = email.isNotEmpty
            ? '@${email.split('@').first}'
            : '@nith_user';

        return Scaffold(
          backgroundColor: NimbusColors.cardBg,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildAvatarSection(
                      context: context,
                      auth: auth,
                      displayName: displayName,
                      handle: handle,
                      photoUrl: photoUrl,
                    ),
                    const SizedBox(height: 8),
                    _buildRankCard(),
                    const SizedBox(height: 8),
                    _buildBadgesCard(),
                    const SizedBox(height: 8),
                    _buildEventsCard(),
                    const SizedBox(height: 8),
                    _buildPointsCard(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context, auth),
                    const SizedBox(height: 12),
                    _buildDeleteAccountButton(context, auth),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      backgroundColor: NimbusColors.blue,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
      title: const Text(
        'Profile',
        style: TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NimbusColors.blueDark,
                NimbusColors.blue,
                Color(0xFF4169E1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Avatar + Info + Stats ──────────────────────────────────────────────────
  Widget _buildAvatarSection({
    required BuildContext context,
    required AuthProvider auth,
    required String displayName,
    required String handle,
    String? photoUrl,
  }) {
    // Derive initials for fallback avatar
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.translate(
                offset: const Offset(0, -24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Profile photo from Google, fallback to initials
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _initialsAvatar(initials),
                              )
                            : _initialsAvatar(initials),
                      ),
                    ),
                    // Crown badge
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: NimbusColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text('👑', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ElevatedButton(
                  onPressed: () => _showEditProfileDialog(
                    context,
                    auth,
                    currentName: displayName,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NimbusColors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Name from Google account
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NimbusColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            handle,
            style: const TextStyle(fontSize: 12, color: NimbusColors.textMuted),
          ),
          const SizedBox(height: 6),
          // NITH chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NimbusColors.blueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 12, color: NimbusColors.blue),
                SizedBox(width: 4),
                Text(
                  'NIT Hamirpur',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NimbusColors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: NimbusColors.border, height: 1),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                _statItem('4500', 'Points', valueColor: NimbusColors.blue),
                _verticalDivider(),
                _statItem('#2', 'Rank'),
                _verticalDivider(),
                _statItem('12', 'Events'),
                _verticalDivider(),
                _statItem('5', 'Badges'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gradient initials avatar (fallback when no photo URL)
  Widget _initialsAvatar(String initials) {
    return Container(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label,
      {Color valueColor = NimbusColors.textPrimary}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  color: NimbusColors.textMuted,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        color: NimbusColors.border,
        margin: const EdgeInsets.symmetric(vertical: 4),
      );

  // ── Rank card ──────────────────────────────────────────────────────────────
  Widget _buildRankCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [NimbusColors.blueDark, NimbusColors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT RANK',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('#2 Overall',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2)),
                  SizedBox(height: 2),
                  Text('Top 1% of all participants',
                      style:
                          TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: NimbusColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Gold',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Badges card ────────────────────────────────────────────────────────────
  Widget _buildBadgesCard() {
    return _sectionCard(
      title: 'Badges Earned',
      trailing: 'View All',
      onTrailingTap: () {},
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _badges.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final b = _badges[i];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: b.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(b.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 50,
                  child: Text(b.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9,
                          color: NimbusColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.2)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Registered events card ─────────────────────────────────────────────────
  Widget _buildEventsCard() {
    return _sectionCard(
      title: 'Registered Events',
      trailing: 'View All',
      onTrailingTap: () {},
      child: Column(
        children: _events
            .map((e) => _eventRow(e, isLast: e == _events.last))
            .toList(),
      ),
    );
  }

  Widget _eventRow(RegisteredEvent e, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [e.thumbGradientStart, e.thumbGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(e.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NimbusColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(e.meta,
                        style: const TextStyle(
                            fontSize: 10,
                            color: NimbusColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: e.tagBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.tag,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: e.tagText)),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: NimbusColors.border),
      ],
    );
  }

  // ── Points activity card ───────────────────────────────────────────────────
  Widget _buildPointsCard() {
    return _sectionCard(
      title: 'Points Activity',
      trailing: 'History',
      onTrailingTap: () {},
      child: Column(
        children: _pointsActivities
            .map((p) =>
                _pointsRow(p, isLast: p == _pointsActivities.last))
            .toList(),
      ),
    );
  }

  Widget _pointsRow(PointsActivity p, {bool isLast = false}) {
    final isPositive = p.points >= 0;
    final color = isPositive ? NimbusColors.green : NimbusColors.red;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.activity,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: NimbusColors.textPrimary)),
                    Text(p.date,
                        style: const TextStyle(
                            fontSize: 10,
                            color: NimbusColors.textMuted)),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${p.points}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: NimbusColors.border),
      ],
    );
  }

  // ── Section card wrapper ───────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required String trailing,
    required VoidCallback onTrailingTap,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NimbusColors.textPrimary)),
                GestureDetector(
                  onTap: onTrailingTap,
                  child: Text(trailing,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NimbusColors.blue)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: NimbusColors.border),
          child,
        ],
      ),
    );
  }

  // ── Logout Button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: Colors.red,
          backgroundColor: Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Log Out'),
              content: const Text(
                  'Are you sure you want to exit your account?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Logout',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            if (!context.mounted) return;
            await auth.logout();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        },
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete Account Button ──────────────────────────────────────────────────
  Widget _buildDeleteAccountButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: const Color(0xFF7F1D1D),
          backgroundColor: const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          // Step 1 — initial warning
          final step1 = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 22),
                  SizedBox(width: 8),
                  Text('Delete Account',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827))),
                ],
              ),
              content: const Text(
                'This will permanently delete your account and all your data '
                '(profile, points, registrations). This cannot be undone.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue',
                      style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
          if (step1 != true) return;
          if (!context.mounted) return;

          // Step 2 — final confirmation
          final step2 = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Are you absolutely sure?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626))),
              content: const Text(
                'Your account and all data will be deleted immediately and '
                'cannot be recovered.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Go Back'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete My Account'),
                ),
              ],
            ),
          );
          if (step2 != true) return;
          if (!context.mounted) return;

          final deleted = await auth.deleteAccount();
          if (!context.mounted) return;

          if (deleted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      auth.errorMessage ?? 'Failed to delete account.')),
            );
          }
        },
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever_outlined, size: 20),
              SizedBox(width: 8),
              Text('Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AuthProvider auth, {
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    final messenger = ScaffoldMessenger.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    final updated = await auth.updateDisplayName(newName);

    if (!context.mounted) return;

    if (updated) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } else if (auth.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }
}
