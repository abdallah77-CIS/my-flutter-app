import '../core/api_client.dart';
import '../core/session.dart';

/// Thin service layer over the existing backend endpoints. Every endpoint
/// below is exactly the one the web frontend already calls — no new routes,
/// no changed contracts.
class DonorApi {
  /* ---------- Auth ---------- */

  /// POST /api/auth/login -> { token, userId, username, role, ... }
  /// Returns the normalised user map that gets persisted in the session.
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final map = res is Map<String, dynamic> ? res : <String, dynamic>{};
    final token = (map['token'] ?? map['accessToken'] ?? map['jwt'])?.toString();
    if (token == null || token.isEmpty) {
      throw ApiError(0, 'Login response did not include a token.');
    }

    // Prefer fields from the response body, fall back to JWT claims —
    // same precedence as the web client.
    final claims = decodeJwtPayload(token);
    final user = <String, dynamic>{
      'userId': map['userId'] ?? map['id'] ?? claims['userId'] ?? claims['id'],
      'username':
          map['username'] ?? claims['username'] ?? claims['sub'],
      'fullName': map['fullName'] ?? claims['fullName'],
      'role': (map['role'] ?? claims['role'] ?? 'DONOR')
          .toString()
          .toUpperCase()
          .replaceAll('ROLE_', ''),
    };

    await Session.save(token, user);
    return user;
  }

  /// POST /api/auth/register
  static Future<void> register(Map<String, dynamic> payload) async {
    await ApiClient.post('/auth/register', payload);
  }

  /* ---------- Profile ---------- */

  /// GET /api/donors/profile
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiClient.get('/donors/profile');
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  /// PUT /api/donors/profile/update — only the fields the web form sends.
  static Future<void> updateProfile({
    required String phone,
    required String location,
    required int age,
    required num weight,
  }) async {
    await ApiClient.put('/donors/profile/update', {
      'phone': phone,
      'location': location,
      'age': age,
      'weight': weight,
    });
  }

  /* ---------- Appointments ---------- */

  /// GET /api/donation-appointments/my
  static Future<List<Map<String, dynamic>>> myAppointments() async =>
      toList(await ApiClient.get('/donation-appointments/my'));

  /// POST /api/donation-appointments
  /// appointmentDate must be a full LocalDateTime ("yyyy-MM-ddTHH:mm:ss"),
  /// not a bare date — matching what the backend expects.
  static Future<void> bookAppointment({
    required DateTime date,
    required String notes,
  }) async {
    String two(int n) => n.toString().padLeft(2, '0');
    final formatted =
        '${date.year}-${two(date.month)}-${two(date.day)}'
        'T${two(date.hour)}:${two(date.minute)}:00';
    await ApiClient.post('/donation-appointments', {
      'appointmentDate': formatted,
      'notes': notes,
    });
  }

  /// PUT /api/donation-appointments/{id}/cancel
  static Future<void> cancelAppointment(dynamic id) async {
    await ApiClient.put('/donation-appointments/$id/cancel');
  }

  /* ---------- Donations ---------- */

  /// GET /api/donations/my
  static Future<List<Map<String, dynamic>>> myDonations() async =>
      toList(await ApiClient.get('/donations/my'));

  /* ---------- Notifications ---------- */

  /// GET /api/notifications
  static Future<List<Map<String, dynamic>>> notifications() async =>
      toList(await ApiClient.get('/notifications'));

  /// GET /api/notifications/unread
  static Future<List<Map<String, dynamic>>> unreadNotifications() async =>
      toList(await ApiClient.get('/notifications/unread'));

  /// PUT /api/notifications/{id}/read
  static Future<void> markRead(dynamic id) async {
    await ApiClient.put('/notifications/$id/read');
  }

  /// Marks every unread notification as read, same as the web "mark all" action.
  static Future<void> markAllRead() async {
    final unread = await unreadNotifications();
    await Future.wait(unread.map((n) {
      final id = n['notificationId'] ?? n['id'];
      return markRead(id);
    }));
  }
}
