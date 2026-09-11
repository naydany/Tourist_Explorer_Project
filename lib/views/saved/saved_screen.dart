import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/destination.dart';
import '../../stores/favorites_store.dart';
import 'widgets/saved_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({required this.favorites, this.onBrowse, super.key});

  final FavoritesStore favorites;
  final VoidCallback? onBrowse;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String? _category;

  List<Destination> get _visible {
    final all = widget.favorites.all;
    if (_category == null) return all;
    return all.where((d) => d.category == _category).toList(growable: false);
  }

  void _open(Destination destination) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.destination, arguments: destination.id);
  }

  void _unsave(Destination destination) {
    widget.favorites.remove(destination.id);
    // Only clear the chip when the filter in force just lost its last place.
    final category = _category;
    if (category != null && !widget.favorites.categories.contains(category)) {
      setState(() => _category = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Rebuilds whenever a heart is tapped, here or on another tab.
        child: ListenableBuilder(
          listenable: widget.favorites,
          builder: (context, child) {
            if (widget.favorites.isEmpty) {
              return _EmptySaved(onBrowse: widget.onBrowse);
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _Header(
                    count: widget.favorites.count,
                    lastAddedAt: widget.favorites.lastAddedAt,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoryChips(
                    categories: widget.favorites.categories,
                    selected: _category,
                    onSelected: (value) => setState(() => _category = value),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: _visible.length,
                    itemBuilder: (context, index) {
                      final destination = _visible[index];
                      return SavedCard(
                        destination: destination,
                        onTap: () => _open(destination),
                        onUnsave: () => _unsave(destination),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Saved places" and "6 places · last added 2 days ago".
class _Header extends StatelessWidget {
  const _Header({required this.count, required this.lastAddedAt});

  final int count;
  final DateTime? lastAddedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Saved places', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(_subtitle(), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _subtitle() {
    final places = '$count ${count == 1 ? 'place' : 'places'}';
    final added = lastAddedAt;
    if (added == null) return places;
    return '$places · last added ${_relative(added)}';
  }
}

String _relative(DateTime moment) {
  final elapsed = DateTime.now().difference(moment);

  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return _plural(elapsed.inMinutes, 'minute');
  if (elapsed.inDays < 1) return _plural(elapsed.inHours, 'hour');
  if (elapsed.inDays < 30) return _plural(elapsed.inDays, 'day');
  return _plural(elapsed.inDays ~/ 30, 'month');
}

String _plural(int value, String unit) {
  return '$value $unit${value == 1 ? '' : 's'} ago';
}

/// Only the categories actually present in the saved list - no empty filters.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = index == 0 ? null : categories[index - 1];
          return _Chip(
            label: value ?? 'All',
            selected: value == selected,
            onTap: () => onSelected(value),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      selectedColor: theme.colorScheme.primary,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved({this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const _EmptyBadge(),
          const SizedBox(height: 26),
          Text(
            'Your list is empty',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the heart on any destination and it will show up here.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (onBrowse != null) ...<Widget>[
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onBrowse,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Browse destinations',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyBadge extends StatelessWidget {
  const _EmptyBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: <Widget>[
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 34,
              color: colors.primary.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppTheme.star,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
