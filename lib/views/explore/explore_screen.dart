import 'dart:async' show Timer, unawaited;
import 'package:flutter/material.dart' hide Page;

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../models/destination.dart';
import '../../models/page.dart';
import '../../repositories/destination_repository.dart';
import '../../repositories/favorites_store.dart';
import 'widgets/destination_card.dart';
import 'widgets/destination_row.dart';
import 'widgets/filter_sheet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    required this.repository,
    required this.favorites,
    super.key,
  });

  final DestinationRepository repository;
  final FavoritesStore favorites;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Duration _debounce = Duration(milliseconds: 350);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;

  DestinationQuery _query = const DestinationQuery();
  Page<Destination>? _page;
  ApiException? _error;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Kicked off here, not in build - build runs on every keystroke.
    _load();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await widget.repository.getPage(
        _query,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final current = _page;
    if (current == null || !current.hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final merged = await widget.repository.loadMore(current);
      if (!mounted) return;
      setState(() {
        _page = merged;
        _isLoadingMore = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      _showError(error);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      unawaited(_loadMore());
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final trimmed = text.trim();
      _applyQuery(
        DestinationQuery(
          text: trimmed.isEmpty ? null : trimmed,
          category: _query.category,
          minRating: _query.minRating,
          sort: _query.sort,
        ),
      );
    });
  }

  bool get _isFiltering =>
      _query.text != null ||
      _query.category != null ||
      _query.minRating != null ||
      _query.sort != DestinationQuery.mostPopular;

  bool get _hasFilters =>
      _query.category != null ||
      _query.minRating != null ||
      _query.sort != DestinationQuery.mostPopular;

  Future<void> _openFilters() async {
    final updated = await showFilterSheet(context, _query);
    if (updated != null) _applyQuery(updated);
  }

  void _onCategorySelected(String? category) {
    if (category == _query.category) return;
    _applyQuery(
      DestinationQuery(
        text: _query.text,
        category: category,
        minRating: _query.minRating,
        sort: _query.sort,
      ),
    );
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    _applyQuery(
      DestinationQuery(
        category: _query.category,
        minRating: _query.minRating,
        sort: _query.sort,
      ),
    );
  }

  void _clearAll() {
    _debounceTimer?.cancel();
    _searchController.clear();
    _applyQuery(const DestinationQuery());
  }

  void _removeCategory() {
    _applyQuery(
      DestinationQuery(
        text: _query.text,
        minRating: _query.minRating,
        sort: _query.sort,
      ),
    );
  }

  void _removeMinRating() {
    _applyQuery(
      DestinationQuery(
        text: _query.text,
        category: _query.category,
        sort: _query.sort,
      ),
    );
  }

  void _resetSort() {
    _applyQuery(
      DestinationQuery(
        text: _query.text,
        category: _query.category,
        minRating: _query.minRating,
      ),
    );
  }

  void _applyQuery(DestinationQuery query) {
    if (query == _query) return;
    setState(() {
      _query = query;
      _page = null;
    });
    unawaited(_load());
  }

  void _showError(ApiException error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.favorites,
          builder: (context, _) => RefreshIndicator(
            onRefresh: () => _load(forceRefresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _Greeting(total: _isFiltering ? null : _page?.total),
                ),
                SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                    onFilter: _openFilters,
                    hasFilters: _hasFilters,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _isFiltering
                      ? _AppliedFilters(
                          query: _query,
                          onRemoveSort: _resetSort,
                          onRemoveCategory: _removeCategory,
                          onRemoveMinRating: _removeMinRating,
                          onClearAll: _clearAll,
                        )
                      : _CategoryChips(
                          selected: _query.category,
                          onSelected: _onCategorySelected,
                        ),
                ),
                SliverToBoxAdapter(
                  child: _isFiltering
                      ? _ResultSummary(query: _query, total: _page?.total)
                      : _SectionHeader(
                          title: _sectionTitle,
                          count: _page?.total,
                        ),
                ),
                ..._buildBody(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _sectionTitle {
    if (_query.category != null) return _query.category!;
    return 'Popular Places';
  }

  List<Widget> _buildBody() {
    if (_isLoading) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    final error = _error;
    if (error != null) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorView(
            error: error,
            onRetry: () => _load(forceRefresh: true),
          ),
        ),
      ];
    }

    final page = _page;
    if (page == null || page.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyView(query: _query),
        ),
      ];
    }

    return <Widget>[
      if (_isFiltering)
        SliverList.separated(
          itemCount: page.items.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 20, endIndent: 20),
          itemBuilder: (context, index) {
            final destination = page.items[index];
            return DestinationRow(
              destination: destination,
              onTap: () => _openDetail(destination),
            );
          },
        )
      else
        SliverList.builder(
          itemCount: page.items.length,
          itemBuilder: (context, index) {
            final destination = page.items[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: DestinationCard(
                destination: destination,
                isFavorite: widget.favorites.contains(destination.id),
                onTap: () => _openDetail(destination),
                onFavoriteToggle: () => widget.favorites.toggle(destination),
              ),
            );
          },
        ),
      if (_isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16, bottom: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
    ];
  }

  void _openDetail(Destination destination) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.destination, arguments: destination.id);
  }
}

/// "Where to today?" plus the profile avatar.
class _Greeting extends StatelessWidget {
  const _Greeting({this.total});

  /// Null until the first page lands, and while a filter narrows the results -
  /// the filtered count belongs in [_ResultSummary], not in the greeting.
  final int? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Where to\ntoday?', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(_subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              'SR',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    final count = total;
    if (count == null) return 'Cambodia · explore the country';
    return 'Cambodia · $count ${count == 1 ? 'place' : 'places'} to explore';
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
    required this.hasFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search places, provinces, temples',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClear,
                            tooltip: 'Clear search',
                            iconSize: 18,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: hasFilters
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            child: InkWell(
              onTap: onFilter,
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Icon(
                  Icons.tune,
                  size: 20,
                  color: hasFilters
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kDestinationCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, value) = kDestinationCategories[index];
          final isSelected = value == selected;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            showCheckmark: false,
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            selectedColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}

/// The filters currently in force, each removable, plus a clear-all.
class _AppliedFilters extends StatelessWidget {
  const _AppliedFilters({
    required this.query,
    required this.onRemoveSort,
    required this.onRemoveCategory,
    required this.onRemoveMinRating,
    required this.onClearAll,
  });

  final DestinationQuery query;
  final VoidCallback onRemoveSort;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveMinRating;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chips = <Widget>[
      if (query.sort != DestinationQuery.mostPopular)
        _FilterChip(
          label: sortLabel(query.sort),
          icon: Icons.arrow_downward_rounded,
          highlighted: true,
          onRemove: onRemoveSort,
        ),
      if (query.category != null)
        _FilterChip(
          label: categoryLabel(query.category!),
          onRemove: onRemoveCategory,
        ),
      if (query.minRating != null)
        _FilterChip(
          label: '${query.minRating}+ rating',
          onRemove: onRemoveMinRating,
        ),
    ];

    // A text-only search has nothing to strip off; keep the spacing steady.
    if (chips.isEmpty) return const SizedBox(height: 4);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          for (final chip in chips) ...<Widget>[chip, const SizedBox(width: 8)],
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onRemove,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onRemove;
  final IconData? icon;

  /// The sort chip is filled, as in the design; the rest are outlined.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = highlighted
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Material(
      color: highlighted
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: highlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onRemove,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
              if (icon != null) ...<Widget>[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: foreground),
              ],
              const SizedBox(width: 6),
              Icon(Icons.close, size: 14, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// "12 PLACES · SORTED BY TOP RATED" - what this query actually returned.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.query, this.total});

  final DestinationQuery query;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = total == null
        ? 'SEARCHING'
        : '$total ${total == 1 ? 'PLACE' : 'PLACES'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        '$count · SORTED BY ${sortLabel(query.sort).toUpperCase()}',
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

/// "POPULAR THIS WEEK ————" with the result count once it is known.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        children: <Widget>[
          Text(title.toUpperCase(), style: theme.textTheme.labelSmall),
          if (count != null) ...<Widget>[
            const SizedBox(width: 8),
            Text('($count)', style: theme.textTheme.labelSmall),
          ],
          const SizedBox(width: 12),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final ApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (IconData icon, String headline) = switch (error) {
      NetworkException() => (Icons.wifi_off_rounded, 'No connection'),
      ApiStatusException(isNotFound: true) => (
        Icons.search_off_rounded,
        'Not found',
      ),
      ApiStatusException() => (Icons.cloud_off_rounded, 'Server problem'),
      ParseException() => (Icons.error_outline_rounded, 'Unexpected response'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(headline, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            error.message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.query});

  final DestinationQuery query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = query.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.travel_explore_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('Nothing here yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            text == null
                ? 'No destinations match these filters.'
                : 'No destinations match "$text".',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
