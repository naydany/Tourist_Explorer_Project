import 'package:flutter/material.dart';

import '../../repositories/destination_repository.dart';
import '../../repositories/favorites_store.dart';
import '../../views/destination/destination_detail_screen.dart';
import '../../views/main_screen.dart';

/// [AppRouter.routes].
abstract final class AppRoutes {
  static const String explore = '/';

  static const String destination = '/destination';
}

abstract final class AppRouter {
  static Map<String, WidgetBuilder> routes(
    DestinationRepository destinations,
    FavoritesStore favorites,
    ValueNotifier<ThemeMode> themeMode,
  ) {
    return <String, WidgetBuilder>{
      AppRoutes.explore: (_) => MainScreen(
        destinations: destinations,
        favorites: favorites,
        themeMode: themeMode,
      ),
    };
  }

  static RouteFactory onGenerateRoute(
    DestinationRepository destinations,
    FavoritesStore favorites,
  ) {
    return (RouteSettings settings) {
      if (settings.name != AppRoutes.destination) return null;

      final id = settings.arguments;
      if (id is! int) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => DestinationDetailScreen(
          destinationId: id,
          repository: destinations,
          favorites: favorites,
        ),
      );
    };
  }

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
