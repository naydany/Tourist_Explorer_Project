@Tags(<String>['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/network/api_client.dart';
import 'package:tourist_explorer_project/core/network/api_exception.dart';
import 'package:tourist_explorer_project/repositories/destination_repository.dart';

/// Exercises the real API at 127.0.0.1:8000. Run with:
/// `flutter test test/destination_repository_live_test.dart`
void main() {
  late DestinationRepository repository;

  // `flutter test` reports defaultTargetPlatform as android, so ApiConfig would
  // hand back the 10.0.2.2 emulator alias. Pin the loopback host instead.
  setUp(
    () => repository = DestinationRepository(
      client: ApiClient(baseUrl: 'http://127.0.0.1:8000'),
    ),
  );

  test('getAll returns the first page', () async {
    final page = await repository.getAll();
    expect(page.items, isNotEmpty);
    expect(page.total, greaterThan(0));
  });

  test('loadMore appends the next page', () async {
    final first = await repository.getPage(const DestinationQuery(limit: 5));
    final merged = await repository.loadMore(first);
    expect(merged.items.length, greaterThan(first.items.length));
  });

  test('search filters server-side', () async {
    final page = await repository.search('angkor');
    expect(page.items, isNotEmpty);
  });

  test('search with no matches returns an empty page', () async {
    final page = await repository.search('zzzzz');
    expect(page.isEmpty, isTrue);
  });

  test('byCategory filters', () async {
    final page = await repository.byCategory('Temple');
    expect(page.items.every((d) => d.category == 'Temple'), isTrue);
  });

  test('getFeatured returns a bare list', () async {
    final featured = await repository.getFeatured(limit: 3);
    expect(featured, hasLength(3));
  });

  test('getById fetches detail and caches it', () async {
    final destination = await repository.getById(1);
    expect(destination.id, 1);
    expect(repository.peek(1), isNotNull);
  });

  test('getNearbyTo returns neighbours', () async {
    final nearby = await repository.getNearbyTo(1, radiusKm: 50);
    expect(nearby, isNotEmpty);
  });

  test('a missing id surfaces as ApiStatusException 404', () async {
    await expectLater(
      repository.getById(999999),
      throwsA(
        isA<ApiStatusException>().having(
          (e) => e.isNotFound,
          'isNotFound',
          true,
        ),
      ),
    );
  });
}
