import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourist_explorer_project/models/destination.dart';
import 'package:tourist_explorer_project/stores/favorites_store.dart';

/// Writes happen in the background, so let them settle before reading back.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a saved place survives a restart', () async {
    FavoritesStore().toggle(_angkorWat);
    await _settle();

    // A fresh store stands in for the app being reopened.
    final reopened = FavoritesStore();
    await reopened.load();

    expect(reopened.count, 1);
    expect(reopened.contains(_angkorWat.id), isTrue);
    expect(reopened.all.single.name, 'Angkor Wat');
  });

  test('unsaving is persisted too', () async {
    final store = FavoritesStore()..toggle(_angkorWat);
    await _settle();
    store.toggle(_angkorWat);
    await _settle();

    final reopened = FavoritesStore();
    await reopened.load();

    expect(reopened.isEmpty, isTrue);
  });

  test('clear empties storage', () async {
    FavoritesStore()
      ..toggle(_angkorWat)
      ..toggle(_bayon)
      ..clear();
    await _settle();

    final reopened = FavoritesStore();
    await reopened.load();

    expect(reopened.isEmpty, isTrue);
  });

  test('the saved order is kept, newest first', () async {
    final store = FavoritesStore()..toggle(_angkorWat);
    // Long enough for the two savedAt stamps to differ; real taps are seconds
    // apart, but the test clock would otherwise tie them.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    store.toggle(_bayon);
    await _settle();

    final reopened = FavoritesStore();
    await reopened.load();

    expect(reopened.all.map((d) => d.name), <String>[
      'Bayon Temple',
      'Angkor Wat',
    ]);
  });

  test(
    'unreadable storage leaves an empty store rather than throwing',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'favorites': 'not json',
      });

      final store = FavoritesStore();
      await store.load();

      expect(store.isEmpty, isTrue);
    },
  );

  test('nothing stored yet loads cleanly', () async {
    final store = FavoritesStore();
    await store.load();

    expect(store.isEmpty, isTrue);
  });
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
