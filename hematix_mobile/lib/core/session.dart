import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent session storage — the mobile equivalent of the web client's
/// localStorage helpers. Same keys, same stored user shape, so the two
/// clients stay conceptually identical.
class Session {
  static const _tokenKey = 'hematix_token';
  static const _userKey = 'hematix_user';

  static Future<void> save(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// Decodes a JWT payload without verifying the signature (display use only) —
/// used to fill in user fields the login response may omit, exactly like the
/// web client does.
Map<String, dynamic> decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64.decode(payload));
    final json = jsonDecode(decoded);
    return json is Map<String, dynamic> ? json : {};
  } catch (_) {
    return {};
  }
}
