import 'dart:convert';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'session.dart';

/// Mirrors the web frontend's ApiError so error handling stays identical
/// across both clients (same statuses, same fallback messages).
class ApiError implements Exception {
  final int status;
  final String message;

  /// Raw decoded body — used for field-level validation errors returned as
  /// `{ "email": "must be a valid email" }`.
  final dynamic data;

  ApiError(this.status, this.message, [this.data]);

  /// Field-level errors, when the backend returned a map of field -> message.
  Map<String, String> get fieldErrors {
    if (data is Map) {
      final out = <String, String>{};
      (data as Map).forEach((k, v) {
        if (v is String) out[k.toString()] = v;
        if (v is List && v.isNotEmpty && v.first is String) {
          out[k.toString()] = v.first as String;
        }
      });
      return out;
    }
    return {};
  }

  @override
  String toString() => message;
}

/// Centralized REST client for the Spring Boot backend.
/// This is the mobile equivalent of the web `api.js` — same endpoints,
/// same JWT bearer scheme, same error semantics.
class ApiClient {
  /// Called when a request fails with 401 while a token was attached,
  /// i.e. the session expired. The app wires this to force a logout.
  static void Function()? onSessionExpired;

  static Future<dynamic> _request(
    String method,
    String endpoint, {
    Object? body,
  }) async {
    final token = await Session.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    http.Response response;

    try {
      final encoded = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: encoded);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: encoded);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw ApiError(0, 'Unsupported method $method');
      }
    } catch (_) {
      // Backend unreachable / offline — same message as the web client.
      throw ApiError(
        0,
        'Could not reach the server. Please check your connection and try again.',
      );
    }

    // Read the body once so every branch below can use it.
    dynamic data;
    final text = response.body;
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } catch (_) {
        // Non-JSON body (the AI endpoints return raw text/plain) — keep it.
        data = text;
      }
    }

    // A 401 only means "session expired" when a token was actually sent.
    // On login/register (no token yet) it just means wrong credentials, and
    // must surface as a normal form error instead of logging the user out.
    if (response.statusCode == 401 && token != null && token.isNotEmpty) {
      await Session.clear();
      onSessionExpired?.call();
      throw ApiError(401, 'Your session has expired. Please log in again.');
    }

    if (response.statusCode == 403) {
      throw ApiError(403, "You don't have permission to do that.");
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        response.statusCode,
        _extractErrorMessage(data, response.statusCode),
        data,
      );
    }

    return data;
  }

  static String _extractErrorMessage(dynamic data, int status) {
    if (data != null) {
      if (data is String && data.isNotEmpty) return data;
      if (data is Map) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
        final parts = data.values.whereType<String>().toList();
        if (parts.isNotEmpty) return parts.join(' ');
      }
    }
    switch (status) {
      case 401:
        return 'Invalid email or password.';
      case 404:
        return 'The requested resource was not found.';
      case 500:
        return 'Something went wrong on the server. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static Future<dynamic> get(String endpoint) => _request('GET', endpoint);
  static Future<dynamic> post(String endpoint, [Object? body]) =>
      _request('POST', endpoint, body: body);
  static Future<dynamic> put(String endpoint, [Object? body]) =>
      _request('PUT', endpoint, body: body);
  static Future<dynamic> delete(String endpoint) =>
      _request('DELETE', endpoint);
}

/// The backend sometimes returns a bare list and sometimes a paged object
/// ({ content: [...] }). The web client normalises this via toList() —
/// same logic here so screens never have to care.
List<Map<String, dynamic>> toList(dynamic data) {
  if (data == null) return [];
  if (data is List) {
    return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  if (data is Map) {
    for (final key in ['content', 'data', 'items', 'results']) {
      if (data[key] is List) return toList(data[key]);
    }
  }
  return [];
}
