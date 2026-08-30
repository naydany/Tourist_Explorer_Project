import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/models/destination.dart';

/// Reads the seed file straight from disk rather than through `rootBundle`,
/// so the test exercises the real catalogue without needing asset bundling.
List<Destination> _loadSeed() {
  final raw = File('assets/data/db.json').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['destinations'] as List<dynamic>)
      .map((entry) => Destination.fromJson(entry as Map<String, dynamic>))
      .toList();
}

Map<String, dynamic> _rawEntry() {
  final raw = File('assets/data/db.json').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return Map<String, dynamic>.from(
    (decoded['destinations'] as List<dynamic>).first as Map<String, dynamic>,
  );
}

void main() {
  group('Destination.fromJson', () {
    test('parses every entry in the seed catalogue', () {
      final destinations = _loadSeed();

      expect(destinations, hasLength(22));
      expect(destinations.map((d) => d.id).toSet(), hasLength(22));
      expect(destinations.every((d) => d.name.isNotEmpty), isTrue);
      expect(destinations.every((d) => d.gallery.isNotEmpty), isTrue);
      expect(destinations.every((d) => d.rating > 0 && d.rating <= 5), isTrue);
    });

    test('maps fields onto the right properties', () {
      final angkorWat = _loadSeed().firstWhere((d) => d.id == 1);

      expect(angkorWat.name, 'Angkor Wat');
      expect(angkorWat.category, 'Temple');
      expect(angkorWat.province, 'Siem Reap');
      expect(angkorWat.rating, 4.9);
      expect(angkorWat.reviewCount, 8900);
      expect(angkorWat.gallery, hasLength(3));
      expect(angkorWat.tags, contains('UNESCO'));
      expect(angkorWat.latitude, closeTo(13.4125, 0.0001));
    });

    test('accepts a whole number where a double is expected', () {
      final json = _rawEntry()..['rating'] = 5;

      expect(Destination.fromJson(json).rating, 5.0);
    });

    test('throws when a required field is missing', () {
      final json = _rawEntry()..remove('name');

      expect(() => Destination.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  test('toJson round-trips back to an equal object', () {
    final original = _loadSeed().first;
    final restored = Destination.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(restored, original);
    expect(restored.hashCode, original.hashCode);
  });

  test('value equality distinguishes different destinations', () {
    final seed = _loadSeed();

    expect(seed[0], isNot(seed[1]));
    expect(seed.toSet(), hasLength(22));
  });
}
