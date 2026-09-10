import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/app.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/core/network/api_exception.dart';
import 'package:tourist_explorer_project/datasources/destination_datasource.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/models/page.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';
import 'package:tourist_explorer_project/repositories/favorites_store.dart';
import 'package:tourist_explorer_project/views/destination/destination_detail_screen.dart';

void main() {
  testWidgets('tapping a card opens the detail screen', (tester) async {
    await tester.pumpWidget(
      TouristExplorerApp(
        destinations: DestinationRepository(datasource: _FakeDatasource()),
        favorites: FavoritesStore(),
      ),
    );
    await tester.pump();

    // The default 800x600 test surface puts the card's centre below the fold.
    await tester.ensureVisible(find.text('Bokor Mountain'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bokor Mountain'));
    await tester.pumpAndSettle();

    expect(find.text('ENTRY FEE'), findsOneWidget);
    expect(find.text(r'$3.00'), findsOneWidget);
    expect(find.text('/ person'), findsOneWidget);
    expect(find.text('Daily 06:00 - 18:00'), findsOneWidget);
    expect(find.text('Nov - Feb, early morning'), findsOneWidget);
    expect(find.text('4.7 ★'), findsOneWidget);
    expect(find.text('2,431 reviews'), findsOneWidget);
    expect(find.text('Get directions'), findsOneWidget);
    expect(
      find.textContaining('A 1,080 m plateau above Kampot'),
      findsOneWidget,
    );
  });

  testWidgets('an unseen destination is fetched by id', (tester) async {
    final datasource = _FakeDatasource();
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationId: 12,
          // Nothing cached: the screen must call fetchById itself.
          repository: DestinationRepository(datasource: datasource),
          favorites: FavoritesStore(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();

    await tester.pumpAndSettle();
    expect(find.text('Bokor Mountain'), findsOneWidget);
    expect(datasource.fetchByIdCalls, 1);
  });

  testWidgets('the gallery strip shows the extra images', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationId: 12,
          repository: DestinationRepository(datasource: _FakeDatasource()),
          favorites: FavoritesStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('GALLERY'), findsOneWidget);
    // Cover image plus the two gallery thumbnails.
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('a failed detail fetch offers a retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationId: 12,
          repository: DestinationRepository(datasource: _FailingDatasource()),
          favorites: FavoritesStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('the nearby strip lists neighbouring places', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationId: 12,
          repository: DestinationRepository(datasource: _NearbyDatasource()),
          favorites: FavoritesStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NEARBY'), findsOneWidget);
    expect(find.text('Kampot Riverfront'), findsOneWidget);
  });

  testWidgets('no neighbours means no nearby section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationId: 12,
          repository: DestinationRepository(datasource: _FakeDatasource()),
          favorites: FavoritesStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NEARBY'), findsNothing);
  });

  testWidgets('the destination itself is never listed as its own neighbour', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationId: 12,
          repository: DestinationRepository(
            datasource: _SelfNearbyDatasource(),
          ),
          favorites: FavoritesStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NEARBY'), findsNothing);
  });
}

class _FakeDatasource extends DestinationDatasource {
  _FakeDatasource() : super(ApiClient());

  int fetchByIdCalls = 0;

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
      items: <Destination>[_bokor],
      total: 1,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<Destination> fetchById(int id) async {
    fetchByIdCalls++;
    return _bokor;
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

class _FailingDatasource extends _FakeDatasource {
  @override
  Future<Destination> fetchById(int id) async => throw const NetworkException();
}

class _NearbyDatasource extends _FakeDatasource {
  @override
  Future<List<Destination>> fetchNearbyTo(
    int id, {
    double? radiusKm,
    int limit = 5,
  }) async {
    return const <Destination>[_kampot];
  }
}

/// The API can include the destination you asked about; the screen filters it.
class _SelfNearbyDatasource extends _FakeDatasource {
  @override
  Future<List<Destination>> fetchNearbyTo(
    int id, {
    double? radiusKm,
    int limit = 5,
  }) async {
    return const <Destination>[_bokor];
  }
}

const Destination _kampot = Destination(
  id: 13,
  name: 'Kampot Riverfront',
  shortDescription: 'Sunset drinks along the Praek Tuek Chhu.',
  longDescription: 'Long description.',
  category: 'Town',
  province: 'Kampot',
  address: 'Kampot',
  rating: 4.5,
  reviewCount: 820,
  popularity: 70,
  imageUrl: 'https://example.invalid/kampot.jpg',
  gallery: <String>[],
  openingHours: 'Open 24 hours',
  entryFee: 'Free entry',
  bestTimeToVisit: 'Late afternoon',
  suggestedDuration: '2 hours',
  latitude: 10.6,
  longitude: 104.18,
  tags: <String>['Riverside'],
);

const Destination _bokor = Destination(
  id: 12,
  name: 'Bokor Mountain',
  shortDescription: 'A cool plateau with an abandoned hill station.',
  longDescription:
      'A 1,080 m plateau above Kampot, cool enough for a jacket at dawn. '
      'The road climbs 32 km past waterfalls to an abandoned French hill '
      'station, a wat on the ridge, and views that run all the way to Phu Quoc.',
  category: 'Nature',
  province: 'Kampot',
  address: 'Preah Monivong NP, Kampot',
  rating: 4.7,
  reviewCount: 2431,
  popularity: 76,
  imageUrl: 'https://example.invalid/bokor.jpg',
  gallery: <String>[
    'https://example.invalid/bokor-1.jpg',
    'https://example.invalid/bokor-2.jpg',
  ],
  openingHours: 'Daily 06:00 - 18:00',
  entryFee: r'$3.00 / person',
  bestTimeToVisit: 'Nov - Feb, early morning',
  suggestedDuration: 'Full day',
  latitude: 10.6289,
  longitude: 104.0492,
  tags: <String>['Mountain', 'Views', 'Sunrise'],
);
