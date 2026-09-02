import 'package:flutter/material.dart';

import '../../../repositories/destination_repository.dart';

const List<(String label, String? value)> kDestinationCategories =
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

const List<(String label, String value)> kDestinationSorts = <(String, String)>[
  ('Most popular', DestinationQuery.mostPopular),
  ('Top rated', DestinationQuery.topRated),
  ('Most reviewed', DestinationQuery.mostReviewed),
  ('Name A-Z', DestinationQuery.byName),
];

const List<(String label, double? value)> kMinimumRatings = <(String, double?)>[
  ('Any', null),
  ('4.0+', 4.0),
  ('4.5+', 4.5),
  ('4.8+', 4.8),
];

String sortLabel(String value) {
  for (final (label, sortValue) in kDestinationSorts) {
    if (sortValue == value) return label;
  }
  return value;
}

String categoryLabel(String value) {
  for (final (label, categoryValue) in kDestinationCategories) {
    if (categoryValue == value) return label;
  }
  return value;
}

Future<DestinationQuery?> showFilterSheet(
  BuildContext context,
  DestinationQuery current,
) {
  return showModalBottomSheet<DestinationQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final DestinationQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sort = widget.initial.sort;
  late String? _category = widget.initial.category;
  late double? _minRating = widget.initial.minRating;

  void _reset() {
    setState(() {
      _sort = DestinationQuery.mostPopular;
      _category = null;
      _minRating = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DestinationQuery(
        text: widget.initial.text,
        category: _category,
        province: widget.initial.province,
        tag: widget.initial.tag,
        minRating: _minRating,
        minPopularity: widget.initial.minPopularity,
        sort: _sort,
        limit: widget.initial.limit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('Filter & sort', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 8),
              _Group(
                label: 'SORT BY',
                children: <Widget>[
                  for (final (label, value) in kDestinationSorts)
                    _Choice(
                      label: label,
                      selected: _sort == value,
                      onTap: () => setState(() => _sort = value),
                    ),
                ],
              ),
              _Group(
                label: 'CATEGORY',
                children: <Widget>[
                  for (final (label, value) in kDestinationCategories)
                    _Choice(
                      label: label,
                      selected: _category == value,
                      onTap: () => setState(() => _category = value),
                    ),
                ],
              ),
              _Group(
                label: 'MINIMUM RATING',
                children: <Widget>[
                  for (final (label, value) in kMinimumRatings)
                    _Choice(
                      label: label,
                      selected: _minRating == value,
                      onTap: () => setState(() => _minRating = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Show results'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
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
