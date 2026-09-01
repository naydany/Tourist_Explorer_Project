/// One page of a list endpoint.
///
/// Every collection route on the API answers with this envelope rather than a
/// bare array:
///
/// ```json
/// { "items": [...], "total": 16, "limit": 20, "offset": 0, "hasMore": true }
/// ```
///
/// Generic over the item type so `/destinations` and `/reviews` share it.
class Page<T> {
  const Page({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  /// Decodes the envelope, delegating each entry to [itemFromJson].
  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>;
    final items = rawItems
        .map((entry) => itemFromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
    final total = json['total'] as int;
    final offset = json['offset'] as int;

    return Page<T>(
      items: items,
      total: total,
      limit: json['limit'] as int,
      offset: offset,
      // `hasMore` is optional in the schema; derive it when it is absent.
      hasMore: json['hasMore'] as bool? ?? offset + items.length < total,
    );
  }

  /// An empty first page, useful as a placeholder before the first load.
  static Page<T> empty<T>({int limit = 20}) {
    return Page<T>(
      items: const [],
      total: 0,
      limit: limit,
      offset: 0,
      hasMore: false,
    );
  }

  final List<T> items;

  /// Total matches on the server, not the length of [items].
  final int total;

  final int limit;
  final int offset;

  /// Whether another page exists after this one - drives "load more".
  final bool hasMore;

  /// Offset to request next, or `null` when this is the last page.
  int? get nextOffset => hasMore ? offset + items.length : null;

  bool get isEmpty => items.isEmpty;

  /// Appends a later page onto this one, keeping the newer paging metadata.
  /// Used to accumulate an infinite-scroll list.
  Page<T> merge(Page<T> next) {
    return Page<T>(
      items: <T>[...items, ...next.items],
      total: next.total,
      limit: next.limit,
      offset: offset,
      hasMore: next.hasMore,
    );
  }

  @override
  String toString() => 'Page(${items.length} of $total, offset: $offset)';
}
