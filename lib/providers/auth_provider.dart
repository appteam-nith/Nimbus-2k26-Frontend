import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  String? _userNickname;
  int? _mafiaPoints;
  int? _mafiaRank;

  late final Future<void> _googleInitFuture;
  late final Future<void> _backendWarmupFuture;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userNickname => _userNickname;
  int? get mafiaPoints => _mafiaPoints;
  int? get mafiaRank => _mafiaRank;
  User? get user => FirebaseAuth.instance.currentUser;

  static const String reviewerAllowedEmail = 'reviewer@nith.ac.in';
  static const String reviewerPassword = 'NimbusReviewer@2026#Secure!';

  static bool isAllowedEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith('@nith.ac.in') ||
        normalized == reviewerAllowedEmail;
  }

  AuthProvider() {
    _googleInitFuture = _initGoogleSignIn();
    _backendWarmupFuture = _warmUpBackend();
    _checkExistingAuth();
  }

  Future<void> _initGoogleSignIn() async {
    await GoogleSignIn.instance.initialize();
  }

  Future<void> _warmUpBackend() async {
    await _apiService.warmUp();
  }

  Future<void> _checkExistingAuth() async {
    debugPrint('[Auth] _checkExistingAuth: checking for stored token…');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      debugPrint(
        '[Auth] _checkExistingAuth: ✓ Found stored token (length=${token.length}), setting isAuthenticated=true',
      );
      _isAuthenticated = true;
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
      _userNickname = prefs.getString('user_nickname');
      debugPrint(
        '[Auth] _checkExistingAuth: name=$_userName, email=$_userEmail, nickname=$_userNickname',
      );
      _apiService.setToken(token);
      notifyListeners();
      _fetchAndCacheProfile();
    } else {
      debugPrint(
        '[Auth] _checkExistingAuth: ✗ No stored token — user is NOT authenticated',
      );
    }
  }

  Future<void> _fetchAndCacheProfile() async {
    try {
      final profileData = await _apiService.getUserProfile();
      final userData = profileData['user'] as Map<String, dynamic>?;
      final name = (userData?['full_name'] ?? userData?['name']) as String?;
      final email = userData?['email'] as String?;
      final nicknameRaw = userData?['nickname'];
      final nickname = nicknameRaw is String ? nicknameRaw.trim() : null;
      final pointsCandidate =
          profileData['points'] ??
          profileData['mafia_points'] ??
          userData?['points'] ??
          userData?['mafia_points'];
      final rankCandidate =
          profileData['rank'] ??
          profileData['mafia_rank'] ??
          userData?['rank'] ??
          userData?['mafia_rank'];

      if (name != null && name.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        if (email != null) {
          await prefs.setString('user_email', email);
        }
        _userName = name;
        _userEmail = email;
      }
      if (nickname != null && nickname.isNotEmpty) {
        await prefs.setString('user_nickname', nickname);
        _userNickname = nickname;
      } else {
        await prefs.remove('user_nickname');
        _userNickname = null;
      }

      if (pointsCandidate != null) {
        _mafiaPoints = int.tryParse(pointsCandidate.toString());
      }
      if (rankCandidate != null) {
        _mafiaRank = int.tryParse(rankCandidate.toString());
      }
      notifyListeners();
    } catch (_) {
      // Ignore background refresh errors.
    }
  }

  void _setStatus(AuthStatus status, {String? error}) {
    _status = status;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void syncProfile(ProfileModel profile) {
    if (_userName != null) {
      profile.updateName(_userName!);
    }
  }

  Future<bool> loginAfterOtp(String otp) async {
    _setStatus(AuthStatus.loading);
    try {
      if (otp.length != 4) {
        throw Exception('Please enter the 4-digit code.');
      }

      if (_isAuthenticated || user != null) {
        _setStatus(AuthStatus.success);
        return true;
      }

      final storedToken = await _apiService.getStoredToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        _apiService.setToken(storedToken);
        _isAuthenticated = true;
        _setStatus(AuthStatus.success);
        return true;
      }

      throw Exception('Please sign in again before verifying the code.');
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<bool> resendOtp() async {
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> signInWithGoogle() async {
    // ... [existing implementation]
    // Keeping existing body to avoid overwriting Google sign in.
    debugPrint('[Auth] ── signInWithGoogle START ──────────────────────');
    _setStatus(AuthStatus.loading);
    try {
      debugPrint('[Auth] Step 1: Waiting for Google SDK init…');
      await _googleInitFuture;
      debugPrint('[Auth] Step 1: ✓ Google SDK ready');

      debugPrint('[Auth] Step 2: Waiting for backend warmup…');
      await _backendWarmupFuture.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint(
            '[Auth] Step 2: ⚠ Backend warmup timed out (continuing anyway)',
          );
        },
      );
      debugPrint('[Auth] Step 2: ✓ Backend warmup done');

      debugPrint('[Auth] Step 3: Signing out existing sessions…');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('[Auth] Step 3: ⚠ Firebase signOut error (non-fatal): $e');
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('[Auth] Step 3: ⚠ Google signOut error (non-fatal): $e');
      }
      debugPrint('[Auth] Step 3: ✓ Old sessions cleared');

      debugPrint('[Auth] Step 4: Launching Google sign-in…');
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      debugPrint('[Auth] Step 4: ✓ Google user selected = ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token.');
      }
      debugPrint(
        '[Auth] Step 4: ✓ Got Google idToken (length=${googleAuth.idToken!.length})',
      );

      debugPrint('[Auth] Step 5: Signing into Firebase with credential…');
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed.');
      }
      debugPrint(
        '[Auth] Step 6: ✓ Firebase user = ${firebaseUser.email}, uid=${firebaseUser.uid}',
      );

      debugPrint('[Auth] Step 7: Getting Firebase ID token (forceRefresh)…');
      final String firebaseIdToken = await firebaseUser.getIdToken(true) ?? '';
      if (firebaseIdToken.isEmpty) {
        throw Exception('Failed to generate Firebase ID token.');
      }
      debugPrint(
        '[Auth] Step 7: ✓ Firebase ID token (length=${firebaseIdToken.length}, prefix=${firebaseIdToken.substring(0, firebaseIdToken.length.clamp(0, 30))}...)',
      );
      if (!firebaseIdToken.startsWith('eyJ')) {
        throw Exception(
          'Token does not look like a valid JWT. Got: ${firebaseIdToken.substring(0, 20)}',
        );
      }

      debugPrint('[Auth] Step 8: Sending Firebase ID token to backend…');
      final response = await _apiService.googleSignIn(firebaseIdToken);
      debugPrint(
        '[Auth] Step 8: ✓ Backend response received — success=${response['success']}, hasToken=${response['token'] != null}',
      );

      // ── Defensive extraction — never hard-cast from API responses ──
      final token = response['token'] as String?;
      if (token == null || token.isEmpty) {
        debugPrint(
          '[Auth] Step 8: ✗ Backend did NOT return a token! Full response: $response',
        );
        throw Exception('Backend did not return a token. Check server logs.');
      }

      final userData = response['user'] as Map<String, dynamic>?;
      if (userData == null) {
        debugPrint(
          '[Auth] Step 8: ✗ Backend did NOT return user data! Full response: $response',
        );
        throw Exception('Backend did not return user data.');
      }
      debugPrint('[Auth] Step 8: ✓ user data = $userData');

      _userName = (userData['name'] ?? userData['full_name']) as String?;
      _userEmail = userData['email'] as String?;
      final nicknameRaw = userData['nickname'];
      _userNickname = nicknameRaw is String && nicknameRaw.trim().isNotEmpty
          ? nicknameRaw.trim()
          : null;
      final userId = userData['user_id'] ?? userData['id'] as String?;

      debugPrint(
        '[Auth] Step 9: Saving to SharedPreferences (name=$_userName, email=$_userEmail, userId=$userId)…',
      );
      final prefs = await SharedPreferences.getInstance();
      if (_userName != null) {
        await prefs.setString('user_name', _userName!);
      }
      if (_userEmail != null) {
        await prefs.setString('user_email', _userEmail!);
      }
      if (_userNickname != null) {
        await prefs.setString('user_nickname', _userNickname!);
      } else {
        await prefs.remove('user_nickname');
      }
      if (userId != null) {
        await prefs.setString('user_id', userId);
      }
      await prefs.setString('auth_token', token);
      debugPrint('[Auth] Step 9: ✓ All data saved');

      _apiService.setToken(token);
      _isAuthenticated = true;
      debugPrint(
        '[Auth] Step 10: ✓ isAuthenticated = true — calling notifyListeners',
      );
      _setStatus(AuthStatus.success);
      debugPrint('[Auth] ── signInWithGoogle COMPLETE ✓ ─────────────────');
      return true;
    } catch (e, stack) {
      final errorMsg = _cleanError(e.toString());
      debugPrint('[Auth] ✗ UNHANDLED ERROR: $e');
      debugPrint('[Auth] ✗ Stack trace: $stack');
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      _setStatus(AuthStatus.error, error: errorMsg);
      return false;
    }
  }

  // ── EMAIL AUTHENTICATION ──────────────────────────────────────────────

  Future<bool> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    _setStatus(AuthStatus.loading);
    try {
      await _apiService.emailSignUp(name, email, password);
      // Backend returns {"message": ...}
      _setStatus(AuthStatus.idle);
      // We don't sign in automatically since they need to verify email
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      final response = await _apiService.emailLogin(email, password);

      final token = response['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Backend did not return a token.');
      }

      final userData = response['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('Backend did not return user data.');
      }

      _userName = (userData['name'] ?? userData['full_name']) as String?;
      _userEmail = userData['email'] as String?;
      final nicknameRaw = userData['nickname'];
      _userNickname = nicknameRaw is String && nicknameRaw.trim().isNotEmpty
          ? nicknameRaw.trim()
          : null;
      final userId = (userData['user_id'] ?? userData['id']) as String?;

      final prefs = await SharedPreferences.getInstance();
      if (_userName != null) await prefs.setString('user_name', _userName!);
      if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
      if (_userNickname != null) {
        await prefs.setString('user_nickname', _userNickname!);
      } else {
        await prefs.remove('user_nickname');
      }
      if (userId != null) await prefs.setString('user_id', userId);
      await prefs.setString('auth_token', token);

      _apiService.setToken(token);
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setStatus(AuthStatus.loading);
    try {
      await _apiService.forgotPassword(email);
      _setStatus(AuthStatus.idle);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<bool> updateDisplayName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _setStatus(AuthStatus.error, error: 'Name cannot be empty.');
      return false;
    }

    _errorMessage = null;
    try {
      final response = await _apiService.updateUserProfile(name: trimmedName);
      final userData = response['user'];
      final updatedName = userData is Map<String, dynamic>
          ? (userData['full_name'] ?? userData['name'] ?? trimmedName)
                .toString()
          : trimmedName;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', updatedName);
      _userName = updatedName;

      if (user != null) {
        await user!.updateDisplayName(updatedName);
        await user!.reload();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<bool> updateNickname(String nickname) async {
    final trimmedNickname = nickname.trim();

    _errorMessage = null;
    try {
      final response = await _apiService.updateUserProfile(
        nickname: trimmedNickname,
      );
      final userData = response['user'];
      final updatedNickname = userData is Map<String, dynamic>
          ? (userData['nickname'] as String?)?.trim()
          : trimmedNickname;

      final prefs = await SharedPreferences.getInstance();
      if (updatedNickname != null && updatedNickname.isNotEmpty) {
        _userNickname = updatedNickname;
        await prefs.setString('user_nickname', updatedNickname);
      } else {
        _userNickname = null;
        await prefs.remove('user_nickname');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _setStatus(AuthStatus.loading);
    try {
      await _apiService.deleteAccount();

      // Sign out of Firebase and Google
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }

      // Clear all local state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_nickname');
      await prefs.remove('auth_token');
      await _apiService.clearToken();

      _isAuthenticated = false;
      _userName = null;
      _userEmail = null;
      _userNickname = null;
      _errorMessage = null;
      _status = AuthStatus.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await _googleInitFuture;

    try {
      await _apiService.logout();
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_nickname');
    await prefs.remove('auth_token');
    await _apiService.clearToken();

    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    _userNickname = null;
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  String _cleanError(String raw) {
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return raw;
  }
}
