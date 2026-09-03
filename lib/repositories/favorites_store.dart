import 'package:flutter/foundation.dart';

import '../models/destination.dart';

class FavoritesStore extends ChangeNotifier {
  final Map<int, _Entry> _entries = <int, _Entry>{};

  List<Destination> get all {
    final entries = _entries.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return entries.map((entry) => entry.destination).toList(growable: false);
  }

  int get count => _entries.length;
  bool get isEmpty => _entries.isEmpty;
  DateTime? get lastAddedAt {
    if (_entries.isEmpty) return null;
    return _entries.values
        .map((entry) => entry.savedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  List<String> get categories {
    final categories =
        _entries.values
            .map((entry) => entry.destination.category)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  bool contains(int id) => _entries.containsKey(id);

  void toggle(Destination destination) {
    if (_entries.remove(destination.id) == null) {
      _entries[destination.id] = _Entry(destination, DateTime.now());
    }
    notifyListeners();
  }

  /// Unsaves everything.
  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }

  void remove(int id) {
    if (_entries.remove(id) != null) notifyListeners();
  }
}

class _Entry {
  const _Entry(this.destination, this.savedAt);

  final Destination destination;
  final DateTime savedAt;
}
