import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/app.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/datasources/destination_datasource.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/models/page.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';
import 'package:tourist_explorer_project/repositories/favorites_store.dart';
import 'package:tourist_explorer_project/views/explore/widgets/destination_card.dart';
import 'package:tourist_explorer_project/views/explore/widgets/destination_row.dart';

void main() {
  testWidgets('browsing shows cards and the category chips', (tester) async {
    await tester.pumpWidget(_app(_FakeDatasource()));
    await tester.pump();

    expect(find.byType(DestinationCard), findsAtLeastNWidgets(1));
    expect(find.byType(DestinationRow), findsNothing);
    expect(find.text('Beaches'), findsOneWidget);
    expect(find.textContaining('POPULAR PLACES'), findsOneWidget);
  });

  testWidgets('searching switches to result rows', (tester) async {
    final datasource = _FakeDatasource();
    await tester.pumpWidget(_app(datasource));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'kep');
    // Past the 350ms debounce.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(datasource.lastQuery, 'kep');
    expect(find.byType(DestinationRow), findsNWidgets(2));
    expect(find.byType(DestinationCard), findsNothing);
    expect(find.text('2 PLACES · SORTED BY MOST POPULAR'), findsOneWidget);
    // The row's metadata line: province, category, shortened fee.
    expect(find.text('Kep · Market · \$\$'), findsNothing);
    expect(find.text('Kep · Market · Free'), findsOneWidget);
  });

  testWidgets('the clear button restores browsing', (tester) async {
    await tester.pumpWidget(_app(_FakeDatasource()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'kep');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(DestinationRow), findsNWidgets(2));

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(DestinationCard), findsAtLeastNWidgets(1));
    expect(find.byType(DestinationRow), findsNothing);
  });

  testWidgets('the filter sheet applies a sort and shows a chip', (
    tester,
  ) async {
    final datasource = _FakeDatasource();
    await tester.pumpWidget(_app(datasource));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Filter & sort'), findsOneWidget);
    await tester.ensureVisible(find.text('Top rated'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top rated'));
    await tester.pump();
    await tester.ensureVisible(find.text('Show results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();

    expect(datasource.lastSort, '-rating');
    // Applied filters replace the category chips, and the sort is removable.
    expect(find.text('Top rated'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('2 PLACES · SORTED BY TOP RATED'), findsOneWidget);
    expect(find.byType(DestinationRow), findsNWidgets(2));
  });

  testWidgets('removing the sort chip returns to browsing', (tester) async {
    await tester.pumpWidget(_app(_FakeDatasource()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Top rated'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top rated'));
    await tester.pump();
    await tester.ensureVisible(find.text('Show results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Top rated'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(DestinationCard), findsAtLeastNWidgets(1));
    expect(find.text('Clear all'), findsNothing);
  });
}

Widget _app(DestinationDatasource datasource) {
  return TouristExplorerApp(
    destinations: DestinationRepository(datasource: datasource),
    favorites: FavoritesStore(),
  );
}

class _FakeDatasource extends DestinationDatasource {
  _FakeDatasource() : super(ApiClient());

  String? lastQuery;
  String? lastSort;

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
    lastQuery = query;
    lastSort = sort;
    return Page<Destination>(
      items: <Destination>[_kepCrabMarket, _rabbitIsland],
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

const Destination _rabbitIsland = Destination(
  id: 4,
  name: 'Rabbit Island',
  shortDescription: 'A short boat ride from Kep.',
  longDescription: 'Long description.',
  category: 'Beach',
  province: 'Kep',
  address: 'Koh Tonsay',
  rating: 4.5,
  reviewCount: 860,
  popularity: 70,
  imageUrl: 'https://example.invalid/rabbit.jpg',
  gallery: <String>[],
  openingHours: 'Open 24 hours',
  entryFee: 'Free entry',
  bestTimeToVisit: 'Dry season',
  suggestedDuration: 'Half day',
  latitude: 10.42,
  longitude: 104.38,
  tags: <String>['Island'],
);
