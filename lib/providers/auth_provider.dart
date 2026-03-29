import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Whether a Clerk → backend sync is currently in progress.
  bool _clerkSyncInProgress = false;
  bool get isClerkSyncInProgress => _clerkSyncInProgress;

  // ── state ─────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  // ── login fields ──────────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  // ── signup fields ─────────────────────────────────────────────────
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController signupPassController = TextEditingController();
  bool agreedToTerms = false;

  // ── password strength (0-4) ───────────────────────────────────────
  int _strength = 0;
  int get strength => _strength;

  // ─────────────────────────────────────────────────────────────────

  AuthProvider() {
    _checkExistingAuth();
  }

  /// Check existing token. If found, show home immediately, then fetch
  /// the real user name from the backend in the background so the profile
  /// always shows the correct name even on app restart.
  Future<void> _checkExistingAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
      notifyListeners(); // Show home immediately with cached name

      // Always refresh name from server in the background
      _fetchAndCacheProfile();
    }
  }

  /// Fetch user profile from backend and cache name locally.
  /// Called silently — errors are swallowed (expired token handled gracefully).
  Future<void> _fetchAndCacheProfile() async {
    try {
      final profileData = await _apiService.getUserProfile();
      final user = profileData['user'] as Map<String, dynamic>?;
      final name = user?['full_name'] as String?;
      final email = user?['email'] as String?;
      if (name != null && name.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        if (email != null) await prefs.setString('user_email', email);
        _userName = name;
        _userEmail = email;
        notifyListeners(); // Triggers AuthWrapper → syncProfile()
      }
    } catch (_) {
      // Silently ignore — token may be expired or network unavailable
    }
  }


  /// Push real user name from AuthProvider into ProfileModel.
  /// Called by AuthWrapper on every build when authenticated.
  void syncProfile(ProfileModel profileModel) {
    if (_userName != null && _userName!.isNotEmpty) {
      profileModel.updateName(_userName!);
    }
    if (_userEmail != null && _userEmail!.isNotEmpty) {
      profileModel.updateBio(_userEmail!);
    }
  }

  // ── state helpers ─────────────────────────────────────────────────
  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool val) {
    rememberMe = val;
    notifyListeners();
  }

  void setAgreedToTerms(bool val) {
    agreedToTerms = val;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    int s = 0;
    if (value.length >= 8) s++;
    if (value.contains(RegExp(r'[A-Z]'))) s++;
    if (value.contains(RegExp(r'[0-9]'))) s++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    _strength = s;
    notifyListeners();
  }

  void _setStatus(AuthStatus s, {String? error}) {
    _status = s;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────
  Future<bool> login() async {
    _setStatus(AuthStatus.loading);
    try {
      final response = await _apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final token = response['token'] as String;

      // Save token first so getUserProfile() can use it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _apiService.setToken(token);

      // Fetch real user profile (name, email) immediately after login
      await _fetchAndCacheProfile();

      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────
  /// Registers the user. Returns true so caller navigates to OTP screen.
  /// Actual login (JWT token) happens after OTP verification via [loginAfterOtp].
  Future<bool> signUp() async {
    _setStatus(AuthStatus.loading);
    try {
      // Send OTP to the entered email address
      await _apiService.sendOtp(email: signupEmailController.text.trim());

      _setStatus(AuthStatus.success);
      return true; // Navigate to OTP screen
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  /// Resends the OTP to the signup email
  Future<bool> resendOtp() async {
    _setStatus(AuthStatus.loading);
    try {
      await _apiService.sendOtp(email: signupEmailController.text.trim());
      _setStatus(AuthStatus.idle); // reset to idle so UI doesn't spin forever
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  /// Called after the user completes OTP verification.
  /// Registers the user with the backend, then logs in, fetches profile, and marks authenticated.
  Future<bool> loginAfterOtp(String otp) async {
    _setStatus(AuthStatus.loading);
    try {
      final name =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
              .trim();
      final email = signupEmailController.text.trim();
      final password = signupPassController.text;

      // 1. Register with backend using the OTP
      await _apiService.register(
        name: name,
        email: email,
        password: password,
        otp: otp,
      );

      // Save name locally so profile can show it immediately
      _userName = name;
      _userEmail = email;
      final prefs = await SharedPreferences.getInstance();
      if (name.isNotEmpty) await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);

      // 2. Login to get the JWT token
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      final token = response['token'] as String;

      await prefs.setString('auth_token', token);
      _apiService.setToken(token);

      // Fetch real profile (confirms name etc.)
      await _fetchAndCacheProfile();

      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  // ── Clerk Sign-In (Google OAuth via Clerk) ────────────────────────
  /// Called by [AuthWrapper]'s ClerkAuthBuilder after a Clerk session is
  /// detected (on app start or after Google OAuth via [ClerkSignInScreen]).
  ///
  /// Posts to POST /api/users/sync with the Clerk session token so the
  /// backend creates / updates the DB record, then marks the user authenticated.
  Future<void> handleClerkSignIn(String clerkToken) async {
    if (_isAuthenticated || _clerkSyncInProgress) return;
    _clerkSyncInProgress = true;

    try {
      _apiService.setToken(clerkToken);

      // Persist token immediately so protected API calls work.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', clerkToken);

      // ✅ Navigate home RIGHT AWAY — don't block on backend sync.
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);

      // Background sync — updates name/email but doesn't affect navigation.
      _syncClerkUserInBackground(clerkToken, prefs);
    } catch (e) {
      debugPrint('[AuthProvider] Clerk sign-in setup failed: $e');
    } finally {
      _clerkSyncInProgress = false;
    }
  }

  void _syncClerkUserInBackground(
    String clerkToken,
    SharedPreferences prefs,
  ) {
    _apiService.syncClerkUser(clerkToken).then((syncData) {
      final user = syncData['user'] as Map<String, dynamic>?;
      final name = (user?['full_name'] as String?) ?? '';
      final email = (user?['email'] as String?) ?? '';

      bool changed = false;
      if (name.isNotEmpty && _userName != name) {
        _userName = name;
        prefs.setString('user_name', name);
        changed = true;
      }
      if (email.isNotEmpty && _userEmail != email) {
        _userEmail = email;
        prefs.setString('user_email', email);
        changed = true;
      }
      if (changed) notifyListeners();
    }).catchError((e) {
      debugPrint('[AuthProvider] Background sync failed (non-fatal): $e');
    });
  }

  // ── Logout ─────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    _clearControllers();
    _setStatus(AuthStatus.idle);
  }

  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    signupEmailController.clear();
    rollNoController.clear();
    signupPassController.clear();
  }

  void reset() {
    _isAuthenticated = false;
    _setStatus(AuthStatus.idle, error: null);
  }

  String _cleanError(String raw) {
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return raw;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    signupEmailController.dispose();
    rollNoController.dispose();
    signupPassController.dispose();
    super.dispose();
  }
}
