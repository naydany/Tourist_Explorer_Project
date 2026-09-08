import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/models/destination.dart';

/// A single entry shaped exactly like one the API returns. Kept inline so the
/// test never depends on a data file or a running backend.
Map<String, dynamic> _json() => <String, dynamic>{
  'id': 1,
  'name': 'Angkor Wat',
  'shortDescription': "The world's largest religious monument.",
  'longDescription': 'Long description.',
  'category': 'Temple',
  'province': 'Siem Reap',
  'address': 'Angkor Archaeological Park',
  'rating': 4.9,
  'reviewCount': 8900,
  'popularity': 100,
  'imageUrl': 'https://example.invalid/angkor.jpg',
  'gallery': <String>[
    'https://example.invalid/1.jpg',
    'https://example.invalid/2.jpg',
  ],
  'openingHours': '05:00 - 18:00 daily',
  'entryFee': r'$37 one-day Angkor Pass',
  'bestTimeToVisit': 'November - February',
  'suggestedDuration': 'Half day',
  'latitude': 13.4125,
  'longitude': 103.867,
  'tags': <String>['UNESCO', 'Temple'],
};

void main() {
  group('Destination.fromJson', () {
    test('maps fields onto the right properties', () {
      final destination = Destination.fromJson(_json());

      expect(destination.id, 1);
      expect(destination.name, 'Angkor Wat');
      expect(destination.category, 'Temple');
      expect(destination.province, 'Siem Reap');
      expect(destination.rating, 4.9);
      expect(destination.reviewCount, 8900);
      expect(destination.latitude, closeTo(13.4125, 0.0001));
      expect(destination.longitude, closeTo(103.867, 0.0001));
    });

    test('reads gallery and tags as typed string lists', () {
      final destination = Destination.fromJson(_json());

      expect(destination.gallery, hasLength(2));
      expect(destination.tags, contains('UNESCO'));
    });

    test('accepts a whole number where a double is expected', () {
      // JSON has no separate int/double, so `5` arrives as an int.
      final json = _json()..['rating'] = 5;

      expect(Destination.fromJson(json).rating, 5.0);
    });

    test('throws when a required field is missing', () {
      final json = _json()..remove('name');

      expect(() => Destination.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  test('toJson round-trips back to an equal object', () {
    final original = Destination.fromJson(_json());
    final restored = Destination.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(restored, original);
    expect(restored.hashCode, original.hashCode);
  });

  test('value equality distinguishes different destinations', () {
    final angkorWat = Destination.fromJson(_json());
    final bayon = Destination.fromJson(
      _json()
        ..['id'] = 2
        ..['name'] = 'Bayon Temple',
    );

    expect(angkorWat, isNot(bayon));
    expect(<Destination>{angkorWat, bayon}, hasLength(2));
  });
}
