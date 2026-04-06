import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/profile_model.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_page.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
    }
  }

  String _getGreeting() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = now.hour;
    if (hour < 12) {
      return "Good Morning,";
    } else if (hour < 17) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
  }

  Widget _buildAvatar(String avatarUrl, String initials) {
    if (avatarUrl.isEmpty) {
      return _initialsAvatar(initials);
    }
    
    final uri = Uri.tryParse(avatarUrl);
    final isNetwork = uri?.scheme == 'http' || uri?.scheme == 'https';

    return ClipOval(
      child: isNetwork
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (_, e2, err) => _initialsAvatar(initials),
            )
          : Image.file(
              File(avatarUrl),
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (_, e2, err) => _initialsAvatar(initials),
            ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFEF7DFF), Color(0xFF7C5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProfileModel>(
      builder: (context, auth, profile, _) {
        final user = auth.user;
        final displayName = auth.userName ?? user?.displayName ?? profile.name;
        final avatarUrl = profile.avatarPath.isNotEmpty
            ? profile.avatarPath
            : (user?.photoURL ?? '');
        final initials = displayName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: _buildAvatar(avatarUrl, initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getGreeting(), style: const TextStyle(fontSize: 12)),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isLoggedIn)
                      Text(
                        "Session Active",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),
        );
      },
    );
  }
}
