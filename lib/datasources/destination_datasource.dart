import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/destination.dart';
import '../models/page.dart';

/// Maps the `/destinations` routes onto typed results.
///
/// The only layer that knows endpoint paths and query-parameter names. It adds
/// no caching or business rules - that is the repository's job.
class DestinationDatasource {
  const DestinationDatasource(this._client);

  final ApiClient _client;

  /// `GET /destinations` - browse, search, filter and sort.
  ///
  /// [sort] accepts `id`, `name`, `rating`, `popularity` or `reviewCount`,
  /// with a `-` prefix for descending. Null arguments are omitted from the
  /// query string, so the server's own defaults apply.
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

  /// `GET /destinations/featured` - top entries by popularity, unpaginated.
  Future<List<Destination>> fetchFeatured({int limit = 5}) async {
    final body = await _client.get(
      '/destinations/featured',
      query: <String, Object?>{'limit': limit},
    );
    return _list(body);
  }

  /// `GET /destinations/{id}` - full detail for one destination.
  Future<Destination> fetchById(int id) async {
    final body = await _client.get('/destinations/$id');
    return _single(body);
  }

  /// `GET /destinations/{id}/nearby` - other places around a destination.
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

  // --- decoding -------------------------------------------------------------
  //
  // The three shapes the API returns. Keeping them here means a change to the
  // envelope touches one file.

  Page<Destination> _page(Object? body) {
    if (body is! Map<String, dynamic>) throw const ParseException();
    try {
      return Page<Destination>.fromJson(body, Destination.fromJson);
    } on TypeError {
      throw const ParseException('A destination arrived in an unknown shape.');
    }
  }

  List<Destination> _list(Object? body) {
    // `featured` and `nearby` answer with a bare array.
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
