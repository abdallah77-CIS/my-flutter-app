import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'session.dart';
import '../services/donor_api.dart';

/// Holds the signed-in user for the whole app. Screens read it via Provider
/// and the root widget swaps between login and the donor shell based on it.
class AuthState extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = true;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String get displayName =>
      (_user?['fullName'] ?? _user?['username'] ?? '').toString();

  AuthState() {
    // Force a logout from anywhere the API client detects an expired token.
    ApiClient.onSessionExpired = () => logout();
    _restore();
  }

  Future<void> _restore() async {
    if (await Session.isLoggedIn()) {
      _user = await Session.getUser();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final user = await DonorApi.login(email, password);
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await Session.clear();
    _user = null;
    notifyListeners();
  }
}
