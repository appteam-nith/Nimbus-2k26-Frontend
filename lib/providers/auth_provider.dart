import 'package:flutter/material.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  // ── shared state ─────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isAuthenticated = false;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirm => _obscureConfirm;
  bool get isAuthenticated => _isAuthenticated;

  // ── login fields ─────────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  // ── signup fields ────────────────────────────────────────────────
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController signupPassController = TextEditingController();
  bool agreedToTerms = false;

  // ── password strength (0-4) ───────────────────────────────────────
  int _strength = 0;
  int get strength => _strength;

  // ── otp ──────────────────────────────────────────────────────────
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  // ─────────────────────────────────────────────────────────────────

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
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

  // ── Login ─────────────────────────────────────────────────────────
  Future<bool> login() async {
    _setStatus(AuthStatus.loading);
    try {
      // TODO: replace with real API call
      // final response = await http.post(Uri.parse('$baseUrl/auth/login'), ...);
      await Future.delayed(const Duration(seconds: 1)); // simulate network
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: e.toString());
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────
  Future<bool> signUp() async {
    _setStatus(AuthStatus.loading);
    try {
      // TODO: replace with real API call
      await Future.delayed(const Duration(seconds: 1));
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: e.toString());
      return false;
    }
  }

  // ── OTP verify ────────────────────────────────────────────────────
  Future<bool> verifyOtp() async {
    _setStatus(AuthStatus.loading);
    try {
      // TODO: replace with real API call
      await Future.delayed(const Duration(seconds: 1));
      _isAuthenticated = true;
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: e.toString());
      return false;
    }
  }

  void reset() {
    _isAuthenticated = false;
    _setStatus(AuthStatus.idle, error: null);
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
    for (final c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
