import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/core/network/api_exception.dart';
import 'package:tourist_explorer_project/datasources/destination_datasource.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';
import 'package:tourist_explorer_project/repositories/favorites_store.dart';
import 'package:tourist_explorer_project/views/map/map_screen.dart';
import 'package:tourist_explorer_project/views/map/widgets/map_peek_card.dart';
import 'package:tourist_explorer_project/views/map/widgets/map_pin.dart';

void main() {
  testWidgets('drops a pin for every destination in the viewport', (
    tester,
  ) async {
    final datasource = _FakeDatasource();
    await tester.pumpWidget(_screen(datasource, FavoritesStore()));
    await tester.pumpAndSettle();

    expect(datasource.boundsCalls, 1);
    expect(find.byType(MapPin), findsNWidgets(2));
    expect(find.byType(MapPeekCard), findsNothing);
  });

  testWidgets('tapping a pin opens the peek card', (tester) async {
    // One pin, so `.first` is unambiguous - marker order is not guaranteed.
    await tester.pumpWidget(_screen(_SingleDatasource(), FavoritesStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MapPin).first);
    await tester.pumpAndSettle();

    expect(find.byType(MapPeekCard), findsOneWidget);
    expect(find.text('Angkor Wat'), findsOneWidget);
    // Rating, category and the opening line read off openingHours.
    expect(find.textContaining('4.9 ★ · Temple'), findsOneWidget);
    expect(find.text('Get directions'), findsOneWidget);
  });

  testWidgets('"Saved only" hides pins that are not saved', (tester) async {
    final favorites = FavoritesStore()..toggle(_bayon);
    await tester.pumpWidget(_screen(_FakeDatasource(), favorites));
    await tester.pumpAndSettle();
    expect(find.byType(MapPin), findsNWidgets(2));

    await tester.tap(find.text('Saved only'));
    await tester.pumpAndSettle();

    expect(find.byType(MapPin), findsOneWidget);
  });

  testWidgets('"Nearby" asks the API for places around the centre', (
    tester,
  ) async {
    final datasource = _FakeDatasource();
    await tester.pumpWidget(_screen(datasource, FavoritesStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();

    expect(datasource.nearbyCalls, 1);
  });

  testWidgets('leaving "Nearby" refetches the viewport', (tester) async {
    final datasource = _FakeDatasource();
    await tester.pumpWidget(_screen(datasource, FavoritesStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All pins'));
    await tester.pumpAndSettle();

    // Nearby reads a different endpoint, so returning to the viewport search
    // has to fetch again rather than leave the radius results on the map.
    expect(datasource.nearbyCalls, 1);
    expect(datasource.boundsCalls, 2);
  });

  testWidgets('a failed load shows a retry notice over the map', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(_FailingDatasource(), FavoritesStore()));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach the server.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(MapPin), findsNothing);
  });

  testWidgets('an empty viewport says so without hiding the map', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(_EmptyDatasource(), FavoritesStore()));
    await tester.pumpAndSettle();

    expect(find.text('No destinations in this area.'), findsOneWidget);
  });
}

Widget _screen(DestinationDatasource datasource, FavoritesStore favorites) {
  return MaterialApp(
    home: MapScreen(
      repository: DestinationRepository(datasource: datasource),
      favorites: favorites,
    ),
  );
}

class _FakeDatasource extends DestinationDatasource {
  _FakeDatasource() : super(ApiClient());

  int boundsCalls = 0;
  int nearbyCalls = 0;

  @override
  Future<List<Destination>> fetchInBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    String? category,
  }) async {
    boundsCalls++;
    return const <Destination>[_angkorWat, _bayon];
  }

  @override
  Future<List<Destination>> fetchNearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    int limit = 10,
  }) async {
    nearbyCalls++;
    return const <Destination>[_angkorWat];
  }
}

class _FailingDatasource extends _FakeDatasource {
  @override
  Future<List<Destination>> fetchInBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    String? category,
  }) async {
    throw const NetworkException();
  }
}

class _SingleDatasource extends _FakeDatasource {
  @override
  Future<List<Destination>> fetchInBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    String? category,
  }) async {
    return const <Destination>[_angkorWat];
  }
}

class _EmptyDatasource extends _FakeDatasource {
  @override
  Future<List<Destination>> fetchInBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    String? category,
  }) async {
    return const <Destination>[];
  }
}

const Destination _angkorWat = Destination(
  id: 1,
  name: 'Angkor Wat',
  shortDescription: "The world's largest religious monument.",
  longDescription: 'Long description.',
  category: 'Temple',
  province: 'Siem Reap',
  address: 'Angkor Archaeological Park',
  rating: 4.9,
  reviewCount: 8900,
  popularity: 100,
  imageUrl: 'https://example.invalid/angkor.jpg',
  gallery: <String>[],
  openingHours: '05:00 - 18:00 daily',
  entryFee: r'$37 one-day Angkor Pass',
  bestTimeToVisit: 'November - February',
  suggestedDuration: 'Half day',
  latitude: 13.4125,
  longitude: 103.867,
  tags: <String>['UNESCO'],
);

const Destination _bayon = Destination(
  id: 2,
  name: 'Bayon Temple',
  shortDescription: 'Stone faces at the centre of Angkor Thom.',
  longDescription: 'Long description.',
  category: 'Temple',
  province: 'Siem Reap',
  address: 'Angkor Thom',
  rating: 4.8,
  reviewCount: 6420,
  popularity: 95,
  imageUrl: 'https://example.invalid/bayon.jpg',
  gallery: <String>[],
  openingHours: '07:30 - 17:30 daily',
  entryFee: 'Included in Angkor Pass',
  bestTimeToVisit: 'November - February',
  suggestedDuration: '2 hours',
  latitude: 13.4413,
  longitude: 103.8586,
  tags: <String>['UNESCO'],
);
