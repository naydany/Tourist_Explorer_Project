import 'package:flutter/material.dart';

import 'core/app.dart';
import 'repositories/destination_repository.dart';
import 'repositories/favorites_store.dart';

void main() {
  runApp(
    TouristExplorerApp(
      destinations: DestinationRepository(),
      favorites: FavoritesStore(),
      themeMode: ValueNotifier<ThemeMode>(ThemeMode.system),
    ),
  );
}
