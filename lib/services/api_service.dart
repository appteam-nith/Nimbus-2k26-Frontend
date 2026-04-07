import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class ApiService {
  static const String baseUrl = 'https://nimbus-2k26-backend-olhw.onrender.com';

  // ── Token management ──────────────────────────────────────────────
  String? _token;

  ApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Directly sets the in-memory token (called after login before further API calls)
  void setToken(String token) {
    _token = token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get hasToken => _token != null;

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ── Helper: Build headers with JWT Bearer token ───────────────────
  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // ── Helper: Handle response ────────────────────────────────────────
  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      if (response.statusCode >= 500) {
         throw Exception('Server is temporarily unavailable (Status ${response.statusCode}). Please try again shortly.');
      }
      throw Exception('Unexpected server response (Status ${response.statusCode}): ${response.body.length > 50 ? '${response.body.substring(0, 50)}...' : response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      final msg = body['error'] ?? 'Unauthorized — please login again';
      throw Exception(msg);
    } else if (response.statusCode == 403) {
      final msg = body['error'] ?? 'Forbidden — access denied';
      throw Exception(msg);
    } else {
      final msg = body['error'] ?? body['message'] ?? response.body;
      throw Exception(msg);
    }
  }

  // ── AUTH ENDPOINTS ─────────────────────────────────────────────────

  /// Send Firebase ID token to backend for verification and receive a JWT.
  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'idToken': idToken}),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception(
          'Server is waking up — this can take up to 60 seconds on first login. Please try again.',
        ),
      );

      final data = _handleResponse(response);
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } on Exception {
      rethrow;
    }
  }

  /// Sign up with email
  Future<Map<String, dynamic>> emailSignUp(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/auth/signup'),
        headers: _getHeaders(),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on Exception {
      rethrow;
    }
  }

  /// Login with email
  Future<Map<String, dynamic>> emailLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } on Exception {
      rethrow;
    }
  }

  /// Request password reset email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/auth/forgot-password'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on Exception {
      rethrow;
    }
  }

  /// Reset password using token
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/auth/reset-password?token=$token'),
        headers: _getHeaders(),
        body: jsonEncode({'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on Exception {
      rethrow;
    }
  }


  /// Logout - clears token locally (no backend logout route)
  Future<void> logout() async {
    await clearToken();
  }

  /// Wake up the backend before the user taps sign in.
  Future<void> warmUp() async {
    try {
      await http.get(
        Uri.parse("$baseUrl/api/coreteam"),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      // Warm-up is best effort only.
    }
  }

  // ── USER ENDPOINTS ─────────────────────────────────────────────────

  /// Get user profile (requires auth)
  Future<Map<String, dynamic>> getUserProfile() async {
    await _loadToken(); // ensure latest token
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile'),
      headers: _getHeaders(requiresAuth: true),
    ).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  /// Update user profile — only supports {name} for now
  Future<Map<String, dynamic>> updateUserProfile({required String name}) async {
    await _loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/profile'),
      headers: _getHeaders(requiresAuth: true),
      body: jsonEncode({'name': name}),
    );
    return _handleResponse(response);
  }

  /// Permanently delete the current user's account and all their data
  Future<void> deleteAccount() async {
    await _loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/profile'),
      headers: _getHeaders(requiresAuth: true),
    ).timeout(const Duration(seconds: 30));
    _handleResponse(response);
  }

  /// Update virtual balance
  Future<Map<String, dynamic>> updateBalance({required double money}) async {
    await _loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/balance'),
      headers: _getHeaders(requiresAuth: true),
      body: jsonEncode({'money': money}),
    );
    return _handleResponse(response);
  }

  // ── CORETEAM ENDPOINTS ─────────────────────────────────────────────

  /// Get core team members (public)
  Future<List<dynamic>> getCoreTeam() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coreteam'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'] ?? [];
  }
}
