import 'dart:io';

/// Base URL of the existing Spring Boot backend.
///
/// The web frontend uses `http://localhost:8080/api`, but on mobile
/// "localhost" resolves to the phone/emulator itself, not to the machine
/// running the backend. So the host is picked per-platform:
///
///  - Android emulator : 10.0.2.2  (the emulator's alias for the host machine)
///  - iOS simulator    : localhost (shares the host's network stack)
///  - Real device      : you MUST set [manualHost] to your computer's LAN IP
///    (e.g. "192.168.1.14") and have the phone on the same Wi-Fi.
class ApiConfig {
  /// Set this to your machine's LAN IP when testing on a physical device,
  /// or to your deployed backend host in production. Set to null to fall back
  /// to the automatic emulator/simulator defaults below.
  static const String? manualHost = '192.168.1.15';

  static const int port = 8080;

  static String get _host {
    if (manualHost != null) return manualHost!;
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get baseUrl => 'http://$_host:$port/api';
}
