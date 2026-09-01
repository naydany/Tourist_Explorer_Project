import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Where the Tourist Explorer REST API lives, and how long to wait for it.
///
/// Override at build time so no host is baked into a release:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
abstract final class ApiConfig {
  /// Set via `--dart-define`; empty means "fall back to the local server".
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const int _localPort = 8000;

  /// Base URL without a trailing slash.
  ///
  /// The Android emulator cannot reach the host machine on `127.0.0.1` - that
  /// address is the emulator itself - so it gets the `10.0.2.2` alias instead.
  /// A physical device needs the LAN IP passed through [_override].
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_localPort';
    }
    return 'http://127.0.0.1:$_localPort';
  }

  /// Ceiling on a single request; the API's `?mockDelay=` can exceed this on
  /// purpose, which is a useful way to exercise the timeout path.
  static const Duration timeout = Duration(seconds: 15);
}
