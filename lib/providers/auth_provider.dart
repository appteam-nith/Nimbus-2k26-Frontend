import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '646738-duygsdhasbdja.apps.googleusercontent.com', // Use full client ID for web
    scopes: ['email', 'profile'],
  );

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

  /// Saves token + user info to SharedPreferences and local state.
  Future<void> _saveUserData(String token, String? name, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (name != null && name.isNotEmpty) {
      _userName = name;
      await prefs.setString('user_name', name);
    }
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      await prefs.setString('user_email', email);
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
      final name =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
              .trim();

      // Register with backend
      await _apiService.register(
        name: name,
        email: signupEmailController.text.trim(),
        password: signupPassController.text,
      );

      // Save name locally so OTP screen + profile can show it
      _userName = name;
      _userEmail = signupEmailController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      if (name.isNotEmpty) await prefs.setString('user_name', name);
      await prefs.setString('user_email', signupEmailController.text.trim());

      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  /// Called after the user completes OTP verification.
  /// Logs in, saves the JWT, fetches profile, marks authenticated.
  Future<bool> loginAfterOtp() async {
    _setStatus(AuthStatus.loading);
    try {
      final response = await _apiService.login(
        email: signupEmailController.text.trim(),
        password: signupPassController.text,
      );
      final token = response['token'] as String;

      final prefs = await SharedPreferences.getInstance();
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

  // ── Google Sign-In ─────────────────────────────────────────────────
  Future<bool> googleSignIn() async {
    _setStatus(AuthStatus.loading);
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        _setStatus(AuthStatus.error, error: 'Google sign-in was cancelled');
        return false;
      }

      // Get authentication token
      // On mobile: use idToken
      // On web: idToken may be null, use accessToken instead
      final googleAuth = await account.authentication;
      final token = googleAuth.idToken ?? googleAuth.accessToken;

      if (token == null) {
        _setStatus(
          AuthStatus.error,
          error: 'Failed to authenticate with Google. Please try again.',
        );
        return false;
      }

      // Send to backend with user info
      final response = await _apiService.googleSignIn(
        idToken: token,
        email: account.email,
        displayName: account.displayName,
        googleId: account.id,
      );
      final jwtToken = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>?;
      final name =
          user?['full_name'] as String? ?? account.displayName ?? 'User';
      final email = user?['email'] as String? ?? account.email;

      await _saveUserData(jwtToken, name, email);
      _apiService.setToken(jwtToken);
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      final msg = e.toString().contains('User cancelled')
          ? 'Sign-in cancelled'
          : _cleanError(e.toString());
      _setStatus(AuthStatus.error, error: msg);
      return false;
    }
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
