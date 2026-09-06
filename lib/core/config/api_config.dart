import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const int _localPort = 8000;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_localPort';
    }
    return 'http://127.0.0.1:$_localPort';
  }

  static const Duration timeout = Duration(seconds: 15);
}
