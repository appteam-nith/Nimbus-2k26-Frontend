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

  late final Future<void> _googleInitFuture;
  late final Future<void> _backendWarmupFuture;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  User? get user => FirebaseAuth.instance.currentUser;

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
      _apiService.setToken(token);
      notifyListeners();
      _fetchAndCacheProfile();
    }
  }

  Future<void> _fetchAndCacheProfile() async {
    try {
      final profileData = await _apiService.getUserProfile();
      final userData = profileData['user'] as Map<String, dynamic>?;
      final name = (userData?['full_name'] ?? userData?['name']) as String?;
      final email = userData?['email'] as String?;

      if (name != null && name.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        if (email != null) {
          await prefs.setString('user_email', email);
        }
        _userName = name;
        _userEmail = email;
        notifyListeners();
      }
    } catch (_) {
      // Ignore background refresh errors.
    }
  }

  void syncProfile(ProfileModel profileModel) {
    if (_userName != null && _userName!.isNotEmpty) {
      profileModel.updateName(_userName!);
    }
    if (_userEmail != null && _userEmail!.isNotEmpty) {
      profileModel.updateBio(_userEmail!);
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
    _setStatus(AuthStatus.loading);
    try {
      await _googleInitFuture;
      await _backendWarmupFuture.timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token.');
      }

      const scopes = ['email', 'profile'];
      final clientAuth =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed.');
      }

      final firebaseIdToken = await firebaseUser.getIdToken(true); // forceRefresh=true
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Failed to generate Firebase ID token.');
      }
      // Sanity check: a Firebase JWT always starts with "eyJ"
      debugPrint('[Auth] Firebase ID token prefix: ${firebaseIdToken.substring(0, firebaseIdToken.length.clamp(0, 30))}...');
      if (!firebaseIdToken.startsWith('eyJ')) {
        throw Exception('Token does not look like a valid JWT. Got: ${firebaseIdToken.substring(0, 20)}');
      }

      final response = await _apiService.googleSignIn(firebaseIdToken);

      // ── Defensive extraction — never hard-cast from API responses ──
      final token = response['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Backend did not return a token. Check server logs.');
      }

      final userData = response['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('Backend did not return user data.');
      }

      _userName = (userData['name'] ?? userData['full_name']) as String?;
      _userEmail = userData['email'] as String?;
      final userId = userData['user_id'] as String?;

      final prefs = await SharedPreferences.getInstance();
      if (_userName != null) {
        await prefs.setString('user_name', _userName!);
      }
      if (_userEmail != null) {
        await prefs.setString('user_email', _userEmail!);
      }
      if (userId != null) {
        await prefs.setString('user_id', userId);
      }
      await prefs.setString('auth_token', token);

      _apiService.setToken(token);
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _setStatus(AuthStatus.idle);
        return false;
      }
      await GoogleSignIn.instance.signOut();
      _setStatus(
        AuthStatus.error,
        error: e.description ?? 'Google sign-in failed.',
      );
      return false;
    } catch (e) {
      final errorMsg = _cleanError(e.toString());
      // Always log to console so devs can see the real error in flutter logs
      debugPrint('[AuthProvider] signInWithGoogle error: $e');
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      _setStatus(AuthStatus.error, error: errorMsg);
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
      await prefs.remove('auth_token');
      await _apiService.clearToken();

      _isAuthenticated = false;
      _userName = null;
      _userEmail = null;
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
    await prefs.remove('auth_token');
    await _apiService.clearToken();

    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
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
