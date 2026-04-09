import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/profile_model.dart';
import '../providers/auth_provider.dart';
import 'leaderboard_screen.dart';

// ── Nimbus color tokens ──────────────────────────────────────────────────────
class NimbusColors {
  static const blue = Color(0xFF2D5BE3);
  static const blueLight = Color(0xFFEFF4FF);
  static const blueDark = Color(0xFF1A3BB3);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const cardBg = Color(0xFFF5F6FA);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProfileModel>(
      builder: (context, auth, profile, _) {
        final user = auth.user;
        final displayName = auth.userName ?? user?.displayName ?? 'Nimbus User';
        final email = auth.userEmail ?? user?.email ?? '';
        final handle = email.isNotEmpty
            ? '@${email.split('@').first}'
            : '@nimbus_user';
        final chatNickname = auth.userNickname?.trim();
        final avatarUrl = profile.avatarPath.isNotEmpty
            ? profile.avatarPath
            : user?.photoURL;
        final initials = displayName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

        return Scaffold(
          backgroundColor: NimbusColors.cardBg,
          appBar: AppBar(
            backgroundColor: NimbusColors.blue,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [NimbusColors.blueDark, NimbusColors.blue],
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildProfileCard(
                  context,
                  auth,
                  profile,
                  displayName,
                  handle,
                  chatNickname,
                  email,
                  avatarUrl,
                  initials,
                ),
                const SizedBox(height: 20),
                _buildLeaderboardCard(auth),
                const SizedBox(height: 24),
                _buildActionButtons(context, auth),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AuthProvider auth,
    ProfileModel profile,
    String displayName,
    String handle,
    String? chatNickname,
    String email,
    String? avatarUrl,
    String initials,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFB8B6FF), Color(0xFF5668FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _selectedImagePath != null
                              ? Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _initialsAvatar(initials),
                                )
                              : (avatarUrl != null && avatarUrl.isNotEmpty
                                    ? _buildAvatarImage(avatarUrl, initials)
                                    : _initialsAvatar(initials)),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _pickProfileImage(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: NimbusColors.blue,
                          width: 1.7,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: NimbusColors.blue,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: NimbusColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                handle,
                style: const TextStyle(
                  fontSize: 13,
                  color: NimbusColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NimbusColors.border),
                ),
                child: Text(
                  'Chat nickname: ${chatNickname == null || chatNickname.isEmpty ? 'Not set' : chatNickname}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: NimbusColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: NimbusColors.blueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NimbusColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                profile.bio.isNotEmpty
                    ? profile.bio
                    : 'Tell the community a little about yourself. Tap edit to add your bio.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: NimbusColors.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
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
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String avatarUrl, String initials) {
    final uri = Uri.tryParse(avatarUrl);
    final isNetwork = uri?.scheme == 'http' || uri?.scheme == 'https';

    if (isNetwork) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsAvatar(initials),
      );
    }

    return Image.file(
      File(avatarUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _initialsAvatar(initials),
    );
  }

  Widget _buildLeaderboardCard(AuthProvider auth) {
    final points = auth.mafiaPoints;
    final rank = auth.mafiaRank;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.emoji_events_outlined, color: NimbusColors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Leaderboard stats are loaded from the Mafia game backend.',
                      style: TextStyle(
                        fontSize: 13,
                        color: NimbusColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _statItem(
                      points != null ? points.toString() : '--',
                      'POINTS',
                    ),
                  ),
                  Container(width: 1, height: 54, color: NimbusColors.border),
                  Expanded(
                    child: _statItem(rank != null ? '#$rank' : '--', 'RANK'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  child: const Text('View full leaderboard'),
                ),
              ),
              if (points == null || rank == null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Join the Mafia game to unlock your leaderboard score.',
                    style: TextStyle(
                      fontSize: 12,
                      color: NimbusColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: NimbusColors.blueDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.0,
            color: NimbusColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              final profile = context.read<ProfileModel>();
              _showEditProfileDialog(
                context,
                auth,
                profile,
                currentName:
                    auth.userName ?? auth.user?.displayName ?? 'Nimbus User',
                currentBio: profile.bio,
                currentNickname: auth.userNickname ?? '',
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color.fromARGB(255, 244, 245, 247),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: const BorderSide(color: NimbusColors.blue),
              elevation: 2,
            ),
            label: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NimbusColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm != true || !context.mounted) return;
              await auth.logout();
              if (!context.mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: const BorderSide(color: NimbusColors.blue),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NimbusColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'This will delete your account permanently and cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true || !context.mounted) return;
              final deleted = await auth.deleteAccount();
              if (!context.mounted) return;
              if (deleted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      auth.errorMessage ?? 'Failed to delete account.',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text(
              'Delete Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (bottomContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: NimbusColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Choose Profile Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NimbusColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildImagePickerOption(
                icon: Icons.image,
                label: 'Photo Gallery',
                onTap: () async {
                  print('DEBUG: Photo Gallery tapped');
                  Navigator.pop(bottomContext);
                  print(
                    'DEBUG: Bottom sheet closed, calling _pickImageFromGallery',
                  );
                  await _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 10),
              _buildImagePickerOption(
                icon: Icons.folder,
                label: 'Files',
                onTap: () async {
                  print('DEBUG: Files tapped');
                  Navigator.pop(bottomContext);
                  print(
                    'DEBUG: Bottom sheet closed, calling _pickImageFromFiles',
                  );
                  await _pickImageFromFiles();
                },
              ),
              const SizedBox(height: 10),
              _buildImagePickerOption(
                icon: Icons.close,
                label: 'Cancel',
                onTap: () => Navigator.pop(bottomContext),
                isCancel: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCancel = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isCancel ? Colors.red : NimbusColors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCancel ? Colors.red : NimbusColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('DEBUG: _pickImageFromGallery called');
      final status = await _requestPhotoPermission();
      print('DEBUG: Permission status = $status');

      if (!status.isGranted) {
        print('DEBUG: Permission denied');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo library permission is required.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      print('DEBUG: Permission granted, opening image picker');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      print('DEBUG: Image picked: ${pickedFile?.path}');

      if (pickedFile != null && mounted) {
        final profile = context.read<ProfileModel>();
        await profile.updateAvatar(pickedFile.path);
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('DEBUG: No image selected or widget not mounted');
      }
    } catch (e) {
      print('DEBUG: Error in _pickImageFromGallery: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImageFromFiles() async {
    try {
      print('DEBUG: _pickImageFromFiles called');
      final status = await _requestStoragePermission();
      print('DEBUG: Permission status = $status');

      if (!status.isGranted) {
        print('DEBUG: Permission denied');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File access permission is required.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      print('DEBUG: Permission granted, opening file picker');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );

      print('DEBUG: File picked: ${result?.files.firstOrNull?.path}');

      if (result != null && result.files.isNotEmpty && mounted) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          final profile = context.read<ProfileModel>();
          await profile.updateAvatar(filePath);
          setState(() {
            _selectedImagePath = filePath;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        print('DEBUG: No file selected or widget not mounted');
      }
    } catch (e) {
      print('DEBUG: Error in _pickImageFromFiles: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<PermissionStatus> _requestPhotoPermission() async {
    try {
      print('DEBUG: _requestPhotoPermission called');
      // permission_handler automatically handles Android 13+ vs older versions
      final status = await Permission.photos.request();
      print('DEBUG: Permission.photos result: $status');
      return status;
    } catch (e) {
      print('DEBUG: Error in _requestPhotoPermission: $e');
      rethrow;
    }
  }

  Future<PermissionStatus> _requestStoragePermission() async {
    try {
      print('DEBUG: _requestStoragePermission called');
      // permission_handler automatically handles Android 13+ vs older versions
      final status = await Permission.photos.request();
      print('DEBUG: Permission.photos result: $status');
      return status;
    } catch (e) {
      print('DEBUG: Error in _requestStoragePermission: $e');
      rethrow;
    }
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AuthProvider auth,
    ProfileModel profile, {
    required String currentName,
    required String currentBio,
    required String currentNickname,
  }) async {
    final nameController = TextEditingController(text: currentName);
    final bioController = TextEditingController(text: currentBio);
    final nicknameController = TextEditingController(text: currentNickname);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 580),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [NimbusColors.blueDark, NimbusColors.blue],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Display Name Field
                          _buildEditField(
                            controller: nameController,
                            label: 'Display Name',
                            hint: 'Your name',
                            icon: Icons.person,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 16),
                          // Bio Field
                          _buildEditField(
                            controller: bioController,
                            label: 'Bio',
                            hint: 'Tell community about yourself',
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildEditField(
                            controller: nicknameController,
                            label: 'Chat Nickname',
                            hint: 'Name shown in chat rooms',
                            icon: Icons.badge_outlined,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 16),
                          // Info Text
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NimbusColors.blueLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: NimbusColors.blue,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Profile image is picked from your device.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: NimbusColors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: NimbusColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: NimbusColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            final newBio = bioController.text.trim();
                            final newNickname = nicknameController.text.trim();
                            Navigator.pop(dialogContext);

                            await _saveProfileChanges(
                              context,
                              auth,
                              profile,
                              newName,
                              newBio,
                              newNickname,
                              currentName,
                              currentBio,
                              currentNickname,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NimbusColors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
    bioController.dispose();
    nicknameController.dispose();
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: NimbusColors.blue, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NimbusColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: NimbusColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NimbusColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NimbusColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NimbusColors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontSize: 14, color: NimbusColors.textPrimary),
        ),
      ],
    );
  }

  Future<void> _saveProfileChanges(
    BuildContext context,
    AuthProvider auth,
    ProfileModel profile,
    String newName,
    String newBio,
    String newNickname,
    String currentName,
    String currentBio,
    String currentNickname,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (newName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a display name.')),
      );
      return;
    }

    try {
      // Update display name if changed
      if (newName != currentName) {
        final updated = await auth.updateDisplayName(newName);
        if (!updated && auth.errorMessage != null) {
          messenger.showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
          return;
        }
        await profile.updateName(newName);
      }

      // Update bio if changed
      if (newBio != currentBio) {
        await profile.updateBio(newBio);
      }

      // Update chat nickname if changed (blank clears it)
      if (newNickname != currentNickname.trim()) {
        final updated = await auth.updateNickname(newNickname);
        if (!updated && auth.errorMessage != null) {
          messenger.showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
          return;
        }
      }

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
