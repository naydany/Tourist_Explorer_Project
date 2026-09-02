import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/app.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/core/network/api_exception.dart';
import 'package:tourist_explorer_project/datasources/destination_datasource.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/models/page.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';

void main() {
  testWidgets('app boots to the explore screen', (tester) async {
    await tester.pumpWidget(_app(_FakeDatasource()));

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Where to\ntoday?'), findsOneWidget);
  });

  testWidgets('shows a card per destination once loaded', (tester) async {
    await tester.pumpWidget(_app(_FakeDatasource()));
    await tester.pump(); // let the initState future complete

    expect(find.text('Koh Rong'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('BEACH'), findsOneWidget);
    expect(find.textContaining('Preah Sihanouk'), findsOneWidget);
  });

  testWidgets('a network failure shows the retry state', (tester) async {
    await tester.pumpWidget(_app(_FailingDatasource()));
    await tester.pump();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('an empty result shows the empty state', (tester) async {
    await tester.pumpWidget(_app(_EmptyDatasource()));
    await tester.pump();

    expect(find.text('Nothing here yet'), findsOneWidget);
  });
}

Widget _app(DestinationDatasource datasource) {
  return TouristExplorerApp(
    destinations: DestinationRepository(datasource: datasource),
  );
}

/// Stands in for the API. Subclassing keeps the test free of HTTP entirely -
/// no server, no mock adapter.
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
}

class _FailingDatasource extends _FakeDatasource {
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
    throw const NetworkException();
  }
}

class _EmptyDatasource extends _FakeDatasource {
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
    return Page.empty<Destination>();
  }
}

const Destination _kohRong = Destination(
  id: 7,
  name: 'Koh Rong',
  shortDescription:
      'White sand, clear water and bioluminescent plankton after dark.',
  longDescription: 'The largest of Cambodia\'s southern islands.',
  category: 'Beach',
  province: 'Preah Sihanouk',
  address: 'Koh Rong, Preah Sihanouk',
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
  tags: <String>['Island', 'Snorkelling'],
);
