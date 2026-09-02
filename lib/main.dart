import 'package:flutter/material.dart';

import 'core/app.dart';
import 'repositories/destination_repository.dart';
import 'repositories/favorites_store.dart';

void main() {
  // Composition root: both are created once here and shared by every screen.
  runApp(
    TouristExplorerApp(
      destinations: DestinationRepository(),
      favorites: FavoritesStore(),
    ),
  );
}
