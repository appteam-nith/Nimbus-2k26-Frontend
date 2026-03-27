import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';

enum AuthStatus { idle, loading, success, error }

// ── Google OAuth2 config ───────────────────────────────────────────
// Client ID from .env GOOGLE_CLIENT_ID
const String _googleClientId = '646738-duygsdhasbdja';
const String _googleRedirectUrl =
    'com.example.nimbus_2k26_frontend:/oauth2redirect';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

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

  Future<void> _checkExistingAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      _userName = name;
      _userEmail = email;
      notifyListeners();
    }
  }

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

  /// Saves user info to SharedPreferences and updates local state
  Future<void> _saveUserData(
      String token, String? name, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (name != null) {
      _userName = name;
      await prefs.setString('user_name', name);
    }
    if (email != null) {
      _userEmail = email;
      await prefs.setString('user_email', email);
    }
  }

  /// After auth, sync the ProfileModel with the real user name
  void syncProfile(ProfileModel profileModel) {
    if (_userName != null && _userName!.isNotEmpty) {
      profileModel.updateName(_userName!);
    }
    if (_userEmail != null) {
      profileModel.updateBio(_userEmail!);
    }
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

      // Fetch the real user profile to get their name
      final profileData = await _apiService.getUserProfile();
      final user = profileData['user'];
      final name = user?['full_name'] as String?;
      final email = user?['email'] as String?;

      await _saveUserData(token, name, email);
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────
  /// Returns true on successful registration. Caller should navigate to OTP
  /// screen — the actual login happens after OTP verification (verifyAndLogin).
  Future<bool> signUp() async {
    _setStatus(AuthStatus.loading);
    try {
      final name =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
              .trim();
      await _apiService.register(
        name: name,
        email: signupEmailController.text.trim(),
        password: signupPassController.text,
      );
      // Save the name locally so the OTP screen / profile can use it
      _userName = name;
      _userEmail = signupEmailController.text.trim();
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  /// Called after OTP screen — logs in with the credentials from signup
  Future<bool> loginAfterOtp() async {
    _setStatus(AuthStatus.loading);
    try {
      final response = await _apiService.login(
        email: signupEmailController.text.trim(),
        password: signupPassController.text,
      );
      final token = response['token'] as String;
      await _saveUserData(token, _userName, _userEmail);
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: _cleanError(e.toString()));
      return false;
    }
  }

  // ── Google Sign-In via OAuth2 (no Firebase needed) ────────────────
  Future<bool> googleSignIn() async {
    _setStatus(AuthStatus.loading);
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _googleClientId,
          _googleRedirectUrl,
          discoveryUrl:
              'https://accounts.google.com/.well-known/openid-configuration',
          scopes: ['openid', 'email', 'profile'],
          promptValues: ['select_account'],
        ),
      );

      if (result == null || result.idToken == null) {
        _setStatus(AuthStatus.error, error: 'Google sign-in was cancelled');
        return false;
      }

      final response = await _apiService.googleSignIn(idToken: result.idToken!);
      final token = response['token'] as String;
      final user = response['user'];
      final name = user?['name'] as String?;
      final email = user?['email'] as String?;

      await _saveUserData(token, name, email);
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
