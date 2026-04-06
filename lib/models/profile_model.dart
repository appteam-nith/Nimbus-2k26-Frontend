import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ProfileModel extends ChangeNotifier {
  String name;
  String bio;
  String avatarPath;

  ProfileModel({
    this.name = 'Nimbus User',
    this.bio = 'Share a short bio with the community.',
    this.avatarPath = '',
  }) {
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBio = prefs.getString('profile_bio');
    final savedAvatar = prefs.getString('profile_avatar_url');
    if (savedBio != null && savedBio.isNotEmpty) {
      bio = savedBio;
    }
    if (savedAvatar != null && savedAvatar.isNotEmpty) {
      avatarPath = savedAvatar;
    }
    notifyListeners();
  }

  Future<void> updateName(String value) async {
    name = value.trim();
    notifyListeners();
  }

  Future<void> updateBio(String value) async {
    bio = value.trim();
    final prefs = await SharedPreferences.getInstance();
    if (bio.isEmpty) {
      await prefs.remove('profile_bio');
    } else {
      await prefs.setString('profile_bio', bio);
    }
    notifyListeners();
  }

  Future<void> updateAvatar(String path) async {
    avatarPath = path.trim();
    final prefs = await SharedPreferences.getInstance();
    
    if (avatarPath.isEmpty) {
      await prefs.remove('profile_avatar_url');
    } else {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final ext = avatarPath.split('.').last;
        final newFileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final newPath = '${appDir.path}/$newFileName';
        
        final savedFile = await File(avatarPath).copy(newPath);
        
        avatarPath = savedFile.path;
        await prefs.setString('profile_avatar_url', avatarPath);
      } catch (e) {
        if (kDebugMode) {
          print('Error copying profile avatar: $e');
        }
        await prefs.setString('profile_avatar_url', avatarPath);
      }
    }
    notifyListeners();
  }
}
