import 'dart:convert';

// import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../features/destinations/data/models/destination.dart';

class DestinationDatasource {
  static List<Destination>? _cache;

  static Future<List<Destination>> load() async {
    // final list = await DestinationDatasource.load();
    // debugPrint('Loaded ${list.length} destinations');
    // debugPrint(list.first.name);
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString('assets/data/db.json');
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final destinationsJson = jsonMap['destinations'] as List<dynamic>;

    _cache = destinationsJson
        .map((entry) => Destination.fromJson(entry as Map<String, dynamic>))
        .toList();

    return _cache!;
  }
}