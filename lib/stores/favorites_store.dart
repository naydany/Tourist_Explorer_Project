import 'dart:async' show unawaited;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';

class FavoritesStore extends ChangeNotifier {
  static const String _storageKey = 'favorites';

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

  /// Reads saved places back from device storage. Safe to call more than once;
  /// anything unreadable is discarded so a bad write can't wedge the app.
  Future<void> load() async {
    final String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_storageKey);
    } on Object {
      return;
    }
    if (raw == null || raw.isEmpty) return;

    final List<_Entry> restored;
    try {
      restored = (jsonDecode(raw) as List<dynamic>)
          .map((entry) => _Entry.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false);
    } on Object {
      return;
    }

    _entries
      ..clear()
      ..addEntries(
        restored.map(
          (entry) => MapEntry<int, _Entry>(entry.destination.id, entry),
        ),
      );
    notifyListeners();
  }

  void toggle(Destination destination) {
    if (_entries.remove(destination.id) == null) {
      _entries[destination.id] = _Entry(destination, DateTime.now());
    }
    notifyListeners();
    unawaited(_persist());
  }

  /// Unsaves everything.
  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
    unawaited(_persist());
  }

  void remove(int id) {
    if (_entries.remove(id) == null) return;
    notifyListeners();
    unawaited(_persist());
  }

  /// Writes the whole set. The list is small, so rewriting it beats tracking
  /// which entries changed.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(
          _entries.values
              .map((entry) => entry.toJson())
              .toList(growable: false),
        ),
      );
    } on Object {
      // Storage is unavailable; the in-memory list is still correct.
    }
  }
}

class _Entry {
  const _Entry(this.destination, this.savedAt);

  factory _Entry.fromJson(Map<String, dynamic> json) {
    return _Entry(
      Destination.fromJson(json['destination'] as Map<String, dynamic>),
      DateTime.parse(json['savedAt'] as String),
    );
  }

  final Destination destination;
  final DateTime savedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'destination': destination.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };
}
