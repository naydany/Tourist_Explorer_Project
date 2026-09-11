import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/datasources/destination_datasource.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/models/page.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';
import 'package:tourist_explorer_project/stores/favorites_store.dart';
import 'package:tourist_explorer_project/views/profile/profile_screen.dart';

void main() {
  testWidgets('shows the saved and category counts', (tester) async {
    final favorites = FavoritesStore()
      ..toggle(_kohRong)
      ..toggle(_kepCrabMarket);

    await tester.pumpWidget(_screen(favorites: favorites));
    await tester.pump();

    expect(find.text('Guest traveller'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('CATEGORIES'), findsOneWidget);
    // Two saved places across two categories.
    expect(find.text('2'), findsNWidgets(3)); // both tiles, plus the row value
  });

  testWidgets('changing the appearance updates the notifier', (tester) async {
    final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
    await tester.pumpWidget(_screen(themeMode: themeMode));
    await tester.pump();

    expect(find.text('System'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(themeMode.value, ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('clearing saved places asks first, then empties the store', (
    tester,
  ) async {
    final favorites = FavoritesStore()..toggle(_kohRong);
    await tester.pumpWidget(_screen(favorites: favorites));
    await tester.pump();

    await tester.tap(find.text('Clear saved places'));
    await tester.pumpAndSettle();
    expect(find.text('Clear saved places?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(favorites.count, 1);

    await tester.tap(find.text('Clear saved places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(favorites.isEmpty, isTrue);
  });

  testWidgets('the clear-saved row is inert when nothing is saved', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());
    await tester.pump();

    await tester.tap(find.text('Clear saved places'));
    await tester.pumpAndSettle();

    expect(find.text('Clear saved places?'), findsNothing);
  });
}

Widget _screen({
  FavoritesStore? favorites,
  DestinationDatasource? datasource,
  ValueNotifier<ThemeMode>? themeMode,
}) {
  return MaterialApp(
    home: ProfileScreen(
      favorites: favorites ?? FavoritesStore(),
      repository: DestinationRepository(
        datasource: datasource ?? _FakeDatasource(),
      ),
      themeMode: themeMode ?? ValueNotifier<ThemeMode>(ThemeMode.system),
    ),
  );
}

class _FakeDatasource extends DestinationDatasource {
  _FakeDatasource() : super(ApiClient());

  @override
  Future<Page<Destination>> fetchPage({
    String? query,
    String? category,
    String? province,
    String? tag,
    double? minRating,
    int? minPopularity,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    return Page<Destination>(
      items: <Destination>[_kohRong, _kepCrabMarket],
      total: 2,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<List<Destination>> fetchNearbyTo(
    int id, {
    double? radiusKm,
    int limit = 5,
  }) async {
    return const <Destination>[];
  }
}

const Destination _kohRong = Destination(
  id: 7,
  name: 'Koh Rong',
  shortDescription: 'White sand and clear water.',
  longDescription: 'Long description.',
  category: 'Beach',
  province: 'Preah Sihanouk',
  address: 'Koh Rong',
  rating: 4.8,
  reviewCount: 3200,
  popularity: 88,
  imageUrl: 'https://example.invalid/koh-rong.jpg',
  gallery: <String>[],
  openingHours: 'Open 24 hours',
  entryFee: 'Free entry',
  bestTimeToVisit: 'November - April',
  suggestedDuration: '2 days',
  latitude: 10.7,
  longitude: 103.25,
  tags: <String>['Island'],
);

const Destination _kepCrabMarket = Destination(
  id: 3,
  name: 'Kep Crab Market',
  shortDescription: 'Blue swimmer crabs straight off the boat.',
  longDescription: 'Long description.',
  category: 'Market',
  province: 'Kep',
  address: 'Kep',
  rating: 4.9,
  reviewCount: 1240,
  popularity: 80,
  imageUrl: 'https://example.invalid/kep.jpg',
  gallery: <String>[],
  openingHours: '06:00 - 18:00 daily',
  entryFee: 'Free entry',
  bestTimeToVisit: 'Morning',
  suggestedDuration: '2 hours',
  latitude: 10.48,
  longitude: 104.3,
  tags: <String>['Seafood'],
);
