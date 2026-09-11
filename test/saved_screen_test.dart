import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/app.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/datasources/destination_datasource.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/models/page.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';
import 'package:tourist_explorer_project/stores/favorites_store.dart';
import 'package:tourist_explorer_project/views/saved/saved_screen.dart';
import 'package:tourist_explorer_project/views/saved/widgets/saved_card.dart';

void main() {
  group('SavedScreen', () {
    testWidgets('shows the empty state when nothing is saved', (tester) async {
      await tester.pumpWidget(_screen(FavoritesStore()));

      expect(find.text('Your list is empty'), findsOneWidget);
      expect(find.byType(SavedCard), findsNothing);
    });

    testWidgets('the browse button jumps to the Explore tab', (tester) async {
      await tester.pumpWidget(
        TouristExplorerApp(
          destinations: DestinationRepository(datasource: _FakeDatasource()),
          favorites: FavoritesStore(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Your list is empty'), findsOneWidget);

      await tester.tap(find.text('Browse destinations'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Where to'), findsOneWidget);
    });

    testWidgets('lists saved places in a grid', (tester) async {
      final favorites = FavoritesStore()
        ..toggle(_kohRong)
        ..toggle(_kepCrabMarket);

      await tester.pumpWidget(_screen(favorites));

      expect(find.text('Saved places'), findsOneWidget);
      expect(find.textContaining('2 places'), findsOneWidget);
      expect(find.textContaining('last added just now'), findsOneWidget);
      expect(find.byType(SavedCard), findsNWidgets(2));
      expect(find.text('Koh Rong'), findsOneWidget);
      expect(find.text('Kep Crab Market'), findsOneWidget);
    });

    testWidgets('the heart removes a place from the grid', (tester) async {
      final favorites = FavoritesStore()
        ..toggle(_kohRong)
        ..toggle(_kepCrabMarket);

      await tester.pumpWidget(_screen(favorites));
      await tester.tap(find.byTooltip('Remove Koh Rong from saved'));
      await tester.pump();

      expect(find.text('Koh Rong'), findsNothing);
      expect(find.byType(SavedCard), findsOneWidget);
      expect(favorites.count, 1);
    });

    testWidgets('category chips filter the grid', (tester) async {
      final favorites = FavoritesStore()
        ..toggle(_kohRong)
        ..toggle(_kepCrabMarket);

      await tester.pumpWidget(_screen(favorites));

      await tester.tap(find.text('Beach'));
      await tester.pump();

      expect(find.text('Koh Rong'), findsOneWidget);
      expect(find.text('Kep Crab Market'), findsNothing);
    });

    testWidgets('one category means no chips at all', (tester) async {
      final favorites = FavoritesStore()..toggle(_kohRong);

      await tester.pumpWidget(_screen(favorites));

      expect(find.text('All'), findsNothing);
    });
  });

  testWidgets('a heart tapped on Explore appears on the Saved tab', (
    tester,
  ) async {
    final favorites = FavoritesStore();
    await tester.pumpWidget(
      TouristExplorerApp(
        destinations: DestinationRepository(datasource: _FakeDatasource()),
        favorites: favorites,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byTooltip('Save Koh Rong'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save Koh Rong'));
    await tester.pump();

    expect(favorites.contains(_kohRong.id), isTrue);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(find.text('Saved places'), findsOneWidget);
    expect(find.byType(SavedCard), findsOneWidget);
  });
}

Widget _screen(FavoritesStore favorites) {
  return MaterialApp(home: SavedScreen(favorites: favorites));
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
      items: <Destination>[_kohRong],
      total: 1,
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
