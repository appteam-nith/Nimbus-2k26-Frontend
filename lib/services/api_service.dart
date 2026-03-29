import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://nimbus-2k26-backend-2.onrender.com';

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
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized — please login again');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden — access denied');
    } else {
      final msg = body['error'] ?? body['message'] ?? response.body;
      throw Exception(msg);
    }
  }

  // ── AUTH ENDPOINTS ─────────────────────────────────────────────────

  /// Send Firebase ID token to backend for verification and receive a JWT.
  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/auth/google'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'idToken': idToken}),
    );
    
    final data = _handleResponse(response);
    if (data['token'] != null) {
      await _saveToken(data['token']);
    }
    return data;
  }


  /// Logout — clears token locally (no backend logout route)
  Future<void> logout() async {
    await clearToken();
  }

  // ── USER ENDPOINTS ─────────────────────────────────────────────────

  /// Get user profile (requires auth)
  Future<Map<String, dynamic>> getUserProfile() async {
    await _loadToken(); // ensure latest token
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile'),
      headers: _getHeaders(requiresAuth: true),
    );
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
