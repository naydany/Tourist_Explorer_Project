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

  final int total;

  final int limit;
  final int offset;

  final bool hasMore;

  int? get nextOffset => hasMore ? offset + items.length : null;

  bool get isEmpty => items.isEmpty;

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
