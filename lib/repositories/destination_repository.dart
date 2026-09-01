import '../core/network/api_client.dart';
import '../datasources/destination_datasource.dart';
import '../models/destination.dart';
import '../models/page.dart';


class DestinationRepository {
  DestinationRepository({DestinationDatasource? datasource, ApiClient? client})
    : _datasource = datasource ?? DestinationDatasource(client ?? ApiClient());

  final DestinationDatasource _datasource;

  /// Every destination seen so far, by id. Populated by all fetches, so a list
  /// that already showed an entry can hand the detail screen something to
  /// render immediately.
  final Map<int, Destination> _byId = <int, Destination>{};

  /// The most recent browse result, keyed by the filters that produced it.
  /// A repeat of the same query is served from here.
  DestinationQuery? _lastQuery;
  Page<Destination>? _lastPage;

  List<Destination>? _featured;

  /// First page for [query], from cache when the same filters were just used.
  ///
  /// Pass `forceRefresh: true` for pull-to-refresh.
  Future<Page<Destination>> getPage(
    DestinationQuery query, {
    bool forceRefresh = false,
  }) async {
    final cached = _lastPage;
    if (!forceRefresh && cached != null && _lastQuery == query) {
      return cached;
    }

    final page = await _fetch(query, offset: 0);
    _lastQuery = query;
    _lastPage = page;
    return page;
  }

  /// Default browse: the first page sorted by popularity.
  Future<Page<Destination>> getAll({bool forceRefresh = false}) {
    return getPage(const DestinationQuery(), forceRefresh: forceRefresh);
  }

  /// Fetches the page after [current] and returns the two concatenated, so the
  /// caller can assign the result straight back to its list state.
  ///
  /// Returns [current] unchanged when there is nothing left to load.
  Future<Page<Destination>> loadMore(Page<Destination> current) async {
    final offset = current.nextOffset;
    if (offset == null) return current;

    final next = await _fetch(
      _lastQuery ?? const DestinationQuery(),
      offset: offset,
    );
    final merged = current.merge(next);
    _lastPage = merged;
    return merged;
  }

  /// Free-text search over name, descriptions, province and tags.
  Future<Page<Destination>> search(String text, {String? category}) {
    final trimmed = text.trim();
    return getPage(
      DestinationQuery(
        text: trimmed.isEmpty ? null : trimmed,
        category: category,
      ),
    );
  }

  Future<Page<Destination>> byCategory(String category) {
    return getPage(DestinationQuery(category: category));
  }

  Future<Page<Destination>> byProvince(String province) {
    return getPage(DestinationQuery(province: province));
  }

  /// Top destinations by popularity, for the home carousel.
  Future<List<Destination>> getFeatured({
    int limit = 5,
    bool forceRefresh = false,
  }) async {
    final cached = _featured;
    if (!forceRefresh && cached != null && cached.length >= limit) {
      return cached.take(limit).toList(growable: false);
    }

    final featured = await _datasource.fetchFeatured(limit: limit);
    _remember(featured);
    _featured = featured;
    return featured;
  }

  /// One destination in full.
  ///
  /// The list endpoint already returns every field, so a destination seen in a
  /// list is served from cache and the detail screen opens without a spinner.
  Future<Destination> getById(int id, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _byId[id];
      if (cached != null) return cached;
    }

    final destination = await _datasource.fetchById(id);
    _byId[id] = destination;
    return destination;
  }

  /// Other places worth visiting around [id].
  Future<List<Destination>> getNearbyTo(
    int id, {
    double? radiusKm,
    int limit = 5,
  }) async {
    final nearby = await _datasource.fetchNearbyTo(
      id,
      radiusKm: radiusKm,
      limit: limit,
    );
    _remember(nearby);
    return nearby;
  }

  /// Reads without touching the network. Returns null when the id has not been
  /// seen yet - use it to render instantly, then await [getById] for the rest.
  Destination? peek(int id) => _byId[id];

  /// Drops every cached result. The next read hits the API.
  void clearCache() {
    _byId.clear();
    _featured = null;
    _lastQuery = null;
    _lastPage = null;
  }

  /// Single place that turns a [DestinationQuery] into a datasource call, so
  /// adding a filter means touching one argument list rather than three.
  Future<Page<Destination>> _fetch(
    DestinationQuery query, {
    required int offset,
  }) async {
    final page = await _datasource.fetchPage(
      query: query.text,
      category: query.category,
      province: query.province,
      tag: query.tag,
      minRating: query.minRating,
      minPopularity: query.minPopularity,
      sort: query.sort,
      limit: query.limit,
      offset: offset,
    );
    _remember(page.items);
    return page;
  }

  void _remember(Iterable<Destination> destinations) {
    for (final destination in destinations) {
      _byId[destination.id] = destination;
    }
  }
}

/// The filters behind one browse request.
///
/// Value type with `==` so the repository can tell "same query, reuse the
/// cached page" from "the user changed a filter, refetch".
class DestinationQuery {
  const DestinationQuery({
    this.text,
    this.category,
    this.province,
    this.tag,
    this.minRating,
    this.minPopularity,
    this.sort = mostPopular,
    this.limit = 20,
  });

  /// Sort values the API accepts; a `-` prefix means descending.
  static const String mostPopular = '-popularity';
  static const String topRated = '-rating';
  static const String mostReviewed = '-reviewCount';
  static const String byName = 'name';

  /// Free-text search term, or null for "everything".
  final String? text;

  /// One of the API's fixed categories, e.g. `Temple`, `Beach`, `Island`.
  final String? category;

  final String? province;
  final String? tag;
  final double? minRating;
  final int? minPopularity;
  final String sort;
  final int limit;

  DestinationQuery copyWith({
    String? text,
    String? category,
    String? province,
    String? tag,
    double? minRating,
    int? minPopularity,
    String? sort,
    int? limit,
  }) {
    return DestinationQuery(
      text: text ?? this.text,
      category: category ?? this.category,
      province: province ?? this.province,
      tag: tag ?? this.tag,
      minRating: minRating ?? this.minRating,
      minPopularity: minPopularity ?? this.minPopularity,
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DestinationQuery &&
        other.text == text &&
        other.category == category &&
        other.province == province &&
        other.tag == tag &&
        other.minRating == minRating &&
        other.minPopularity == minPopularity &&
        other.sort == sort &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      category,
      province,
      tag,
      minRating,
      minPopularity,
      sort,
      limit,
    );
  }

  @override
  String toString() {
    return 'DestinationQuery(text: $text, category: $category, '
        'province: $province, sort: $sort)';
  }
}
