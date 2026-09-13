import 'package:flutter/material.dart';

import '../repositories/destination_repository.dart';
import '../stores/favorites_store.dart';
import '../views/main_screen.dart';
import 'constants/app_constants.dart';
import 'theme/app_theme.dart';

class TouristExplorerApp extends StatelessWidget {
  TouristExplorerApp({
    required this.destinations,
    required this.favorites,
    ValueNotifier<ThemeMode>? themeMode,
    super.key,
  }) : themeMode = themeMode ?? ValueNotifier<ThemeMode>(ThemeMode.system);

  final DestinationRepository destinations;
  final FavoritesStore favorites;

  /// The Me tab writes to this; the whole app repaints in the chosen mode.
  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, child) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: MainScreen(
          destinations: destinations,
          favorites: favorites,
          themeMode: themeMode,
        ),
      ),
    );
  }
}
