import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  int _page = 1;
  final int _perPage = 15;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _page = 1;
      _fetchLeaderboard();
    });
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _loading = true;
    });

    try {
      final resp = await _api.getLeaderboard(
        page: _page,
        perPage: _perPage,
        q: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      final data = resp['data'] as List<dynamic>? ?? [];
      setState(() {
        _items = data;
        _total = resp['total'] ?? 0;
        _totalPages = resp['total_pages'] ?? 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leaderboard: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index] as Map<String, dynamic>;
    final rank = (_page - 1) * _perPage + index + 1;
    final name = item['name'] ?? 'Unknown';
    final points = item['points']?.toString() ?? '0';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2D5BE3),
        child: Text(
          '#$rank',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('Points: $points'),
      trailing: Text(
        points,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A3BB3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF2D5BE3),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search player name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _page = 1;
                _fetchLeaderboard();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _page = 1;
                await _fetchLeaderboard();
              },
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No players found')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: _buildItem,
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: $_total'),
                Row(
                  children: [
                    Text('Page $_page / $_totalPages'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _page > 1 && !_loading
                          ? () {
                              setState(() => _page = _page - 1);
                              _fetchLeaderboard();
                            }
                          : null,
                      child: const Text('Prev'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _page < _totalPages && !_loading
                          ? () {
                              setState(() => _page = _page + 1);
                              _fetchLeaderboard();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5BE3),
                      ),
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
