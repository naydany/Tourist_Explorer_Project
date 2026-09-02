import 'package:flutter/material.dart';

import '../../../models/destination.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    required this.destination,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    super.key,
  });

  final Destination destination;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Cover(
              destination: destination,
              isFavorite: isFavorite,
              onFavoriteToggle: onFavoriteToggle,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(destination.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  _PlaceLine(destination: destination),
                  const SizedBox(height: 10),
                  Text(
                    destination.shortDescription,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  _TagRow(destination: destination),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Image, rating badge and favourite button.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.destination,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Destination destination;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            destination.imageUrl,
            fit: BoxFit.cover,
            // Hold the layout with the placeholder tint rather than jumping
            // when the bytes land.
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(color: colors.surfaceContainerHighest);
            },
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.onSurfaceVariant,
                ),
              );
            },
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: _RatingBadge(rating: destination.rating),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _FavoriteButton(
              isFavorite: isFavorite,
              onPressed: onFavoriteToggle,
              name: destination.name,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.star_rounded,
              size: 15,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.surface,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onPressed,
    required this.name,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        tooltip: isFavorite ? 'Remove $name from saved' : 'Save $name',
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? colors.error : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Province and how long to set aside, e.g. "Preah Sihanouk · Half day".
class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Icon(
          Icons.place_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${destination.province} · ${destination.suggestedDuration}',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Category and first tag as outlined pills, with the entry fee trailing.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = <String>[
      destination.category,
      if (destination.tags.isNotEmpty) destination.tags.first,
    ];

    return Row(
      children: <Widget>[
        for (final (index, label) in labels.indexed) ...<Widget>[
          _TagChip(
            label: label,
            // Alternate the two accents from the palette, as in the design.
            color: index.isEven
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        Flexible(
          child: Text(
            destination.entryFee,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
