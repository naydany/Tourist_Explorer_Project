import 'package:flutter/material.dart';

import '../../views/home_screen.dart';

/// Named route constants. Add one entry here per screen, then wire it in
/// [AppRouter.routes].
abstract final class AppRoutes {
  static const String home = '/';
}

abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.home: (_) => const HomeScreen(),
  };

  static Route<void> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(child: Text('No route defined for ${settings.name}')),
      ),
    );
  }
}
