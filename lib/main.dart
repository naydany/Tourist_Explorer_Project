import 'package:flutter/material.dart';

import 'core/app.dart';
import 'repositories/destination_repository.dart';
import 'stores/favorites_store.dart';

Future<void> main() async {
  // Required before touching platform channels (shared_preferences) here.
  WidgetsFlutterBinding.ensureInitialized();

  final favorites = FavoritesStore();
  // Restore saved places first, so the Saved tab is correct on the first frame.
  await favorites.load();

  runApp(
    TouristExplorerApp(
      destinations: DestinationRepository(),
      favorites: favorites,
      themeMode: ValueNotifier<ThemeMode>(ThemeMode.system),
    ),
  );
}
