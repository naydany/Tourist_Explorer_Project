import 'dart:async' show Timer, unawaited;
import 'package:flutter/material.dart' hide Page;

import '../../../core/network/api_exception.dart';
import '../../../models/destination.dart';
import '../../../models/page.dart';
import '../../../repositories/destination_repository.dart';
import '../widgets/destination_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.repository, super.key});

  final DestinationRepository repository;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Duration _debounce = Duration(milliseconds: 350);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Set<int> _favorites = <int>{};

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

  /// Pulls the next page in once the list is near its end.
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
        ),
      );
    });
  }

  void _onCategorySelected(String? category) {
    if (category == _query.category) return;
    _applyQuery(DestinationQuery(text: _query.text, category: category));
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
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            // Always scrollable so pull-to-refresh works on the error and
            // empty states too.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              const SliverToBoxAdapter(child: _Greeting()),
              SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
              ),
              SliverToBoxAdapter(
                child: _CategoryChips(
                  selected: _query.category,
                  onSelected: _onCategorySelected,
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
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
    );
  }

  String get _sectionTitle {
    if (_query.text != null) return 'Search results';
    if (_query.category != null) return _query.category!;
    return 'Popular this week';
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
      SliverList.builder(
        itemCount: page.items.length,
        itemBuilder: (context, index) {
          final destination = page.items[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: DestinationCard(
              destination: destination,
              isFavorite: _favorites.contains(destination.id),
              onTap: () => _openDetail(destination),
              onFavoriteToggle: () => _toggleFavorite(destination.id),
            ),
          );
        },
      ),
      if (_isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
    ];
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (!_favorites.remove(id)) _favorites.add(id);
    });
  }

  void _openDetail(Destination destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${destination.name} - detail screen coming soon'),
      ),
    );
  }
}

/// "Where to today?" plus the profile avatar.
class _Greeting extends StatelessWidget {
  const _Greeting();

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
                Text(
                  'Cambodia · 16 places to explore',
                  style: theme.textTheme.bodySmall,
                ),
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
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search places, towns, temples',
          prefixIcon: Icon(Icons.search, size: 20),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  static const List<(String label, String? value)> _categories =
      <(String, String?)>[
        ('All', null),
        ('Beaches', 'Beach'),
        ('Temples', 'Temple'),
        ('Nature', 'Nature'),
        ('Islands', 'Island'),
        ('Waterfalls', 'Waterfall'),
        ('Museums', 'Museum'),
        ('Historical', 'Historical'),
        ('Markets', 'Market'),
        ('Wildlife', 'Wildlife'),
        ('Cities', 'City'),
      ];

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
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, value) = _categories[index];
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
                ? 'No destinations match this filter.'
                : 'No destinations match "$text".',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
