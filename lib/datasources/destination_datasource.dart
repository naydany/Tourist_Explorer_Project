import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/destination.dart';
import '../models/page.dart';

class DestinationDatasource {
  const DestinationDatasource(this._client);

  final ApiClient _client;

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
    final body = await _client.get(
      '/destinations',
      query: <String, Object?>{
        'q': query,
        'category': category,
        'province': province,
        'tag': tag,
        'minRating': minRating,
        'minPopularity': minPopularity,
        'sort': sort,
        'limit': limit,
        'offset': offset,
      },
    );
    return _page(body);
  }

  Future<List<Destination>> fetchFeatured({int limit = 5}) async {
    final body = await _client.get(
      '/destinations/featured',
      query: <String, Object?>{'limit': limit},
    );
    return _list(body);
  }

  Future<Destination> fetchById(int id) async {
    final body = await _client.get('/destinations/$id');
    return _single(body);
  }

  /// `GET /destinations/map` - everything inside a map viewport.
  Future<List<Destination>> fetchInBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    String? category,
  }) async {
    final body = await _client.get(
      '/destinations/map',
      query: <String, Object?>{
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'category': category,
      },
    );
    return _list(body);
  }

  /// `GET /destinations/nearby` - places around a point, nearest first.
  Future<List<Destination>> fetchNearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    int limit = 10,
  }) async {
    final body = await _client.get(
      '/destinations/nearby',
      query: <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'limit': limit,
      },
    );
    return _list(body);
  }

  Future<List<Destination>> fetchNearbyTo(
    int id, {
    double? radiusKm,
    int limit = 5,
  }) async {
    final body = await _client.get(
      '/destinations/$id/nearby',
      query: <String, Object?>{'radiusKm': radiusKm, 'limit': limit},
    );
    return _list(body);
  }

  Page<Destination> _page(Object? body) {
    if (body is! Map<String, dynamic>) throw const ParseException();
    try {
      return Page<Destination>.fromJson(body, Destination.fromJson);
    } on TypeError {
      throw const ParseException('A destination arrived in an unknown shape.');
    }
  }

  List<Destination> _list(Object? body) {
    if (body is! List<dynamic>) throw const ParseException();
    try {
      return body
          .map((entry) => Destination.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false);
    } on TypeError {
      throw const ParseException('A destination arrived in an unknown shape.');
    }
  }

  Destination _single(Object? body) {
    if (body is! Map<String, dynamic>) throw const ParseException();
    try {
      return Destination.fromJson(body);
    } on TypeError {
      throw const ParseException('A destination arrived in an unknown shape.');
    }
  }
}
