import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/leaderboard_screen.dart';

class TopPerformers extends StatefulWidget {
  const TopPerformers({super.key});

  @override
  State<TopPerformers> createState() => _TopPerformersState();
}

class _TopPerformersState extends State<TopPerformers> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchTop();
  }

  Future<void> _fetchTop() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.getLeaderboard(page: 1, perPage: 3);
      final data = resp['data'] as List<dynamic>? ?? [];
      setState(() => _items = data);
    } catch (_) {
      // ignore errors; keep fallback static content if any
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return "?";
    final parts = name.trim().split(RegExp('\\s+'));
    final initials = parts
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    return initials.isEmpty ? '?' : initials;
  }

  void _openFullLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const LeaderboardScreen()),
    );
  }

  Widget _buildPerformer(Map<String, dynamic> p, {required bool isTop}) {
    final name = (p['name'] ?? 'Unknown') as String;
    final points = (p['points']?.toString() ?? '0');
    final rank = p['rank'] ?? 0;
    final avatarRadius = isTop ? 34.0 : 26.0;

    return GestureDetector(
      onTap: _openFullLeaderboard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isTop)
                Container(
                  width: avatarRadius * 2 + 10,
                  height: avatarRadius * 2 + 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: avatarRadius - 3,
                  backgroundColor: const Color(0xFF2D5BE3),
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (isTop)
                const Positioned(
                  top: -14,
                  child: Icon(
                    Icons.emoji_events,
                    color: Color(0xFFFFC107),
                    size: 22,
                  ),
                ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isTop
                        ? const Color(0xFFFFC107)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    rank.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isTop ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$points pts",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // API returns highest first. Layout expects [2nd, 1st, 3rd]
    Map<String, dynamic>? first;
    Map<String, dynamic>? second;
    Map<String, dynamic>? third;

    if (_items.isNotEmpty) {
      first = _items.length > 0 ? Map<String, dynamic>.from(_items[0]) : null;
      second = _items.length > 1 ? Map<String, dynamic>.from(_items[1]) : null;
      third = _items.length > 2 ? Map<String, dynamic>.from(_items[2]) : null;
    }

    // Fallback static content when no data
    final fallback = [
      {'name': 'John Doe', 'points': '4500', 'rank': 1},
      {'name': 'John', 'points': '4200', 'rank': 2},
      {'name': 'Alex', 'points': '3900', 'rank': 3},
    ];

    final leftData = first == null
        ? {
            'name': fallback[1]['name'],
            'points': fallback[1]['points'],
            'rank': fallback[1]['rank'],
          }
        : {
            'name': second?['name'] ?? '',
            'points': second?['points'] ?? '0',
            'rank': second?['rank'] ?? '',
          };

    final centerData = first == null
        ? {
            'name': fallback[0]['name'],
            'points': fallback[0]['points'],
            'rank': fallback[0]['rank'],
          }
        : {
            'name': first?['name'] ?? '',
            'points': first?['points'] ?? '0',
            'rank': first?['rank'] ?? '',
          };

    final rightData = first == null
        ? {
            'name': fallback[2]['name'],
            'points': fallback[2]['points'],
            'rank': fallback[2]['rank'],
          }
        : {
            'name': third?['name'] ?? '',
            'points': third?['points'] ?? '0',
            'rank': third?['rank'] ?? '',
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Top Performers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: _openFullLeaderboard,
              child: const Text(
                "View All",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openFullLeaderboard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPerformer(
                Map<String, dynamic>.from(leftData),
                isTop: false,
              ),
              _buildPerformer(
                Map<String, dynamic>.from(centerData),
                isTop: true,
              ),
              _buildPerformer(
                Map<String, dynamic>.from(rightData),
                isTop: false,
              ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
