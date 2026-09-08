import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;

abstract final class ApiConfig {

  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static const int _localPort = 8000;

  /// Inside the Android emulator, this address means "the host machine".
  static const String _androidEmulatorHost = '10.0.2.2';

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _withoutTrailingSlash(_baseUrlOverride);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_androidEmulatorHost:$_localPort';
    }
    return 'http://127.0.0.1:$_localPort';
  }

  /// Short: an unreachable server should fail fast instead of hanging the UI.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Longer: list endpoints such as `/destinations/map` return every pin.
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const Duration sendTimeout = Duration(seconds: 30);

  static bool get enableLogging => kDebugMode;

  static String _withoutTrailingSlash(String url) =>
      url.replaceAll(RegExp(r'/+$'), '');
}
