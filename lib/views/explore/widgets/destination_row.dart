import 'package:flutter/material.dart';

import '../../../models/destination.dart';

class DestinationRow extends StatelessWidget {
  const DestinationRow({required this.destination, this.onTap, super.key});

  final Destination destination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                destination.imageUrl,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _Thumbnail(color: colors.surfaceContainerHighest);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _Thumbnail(color: colors.surfaceContainerHighest);
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    destination.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _metadata(destination),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      destination.rating.toStringAsFixed(1),
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.star_rounded, size: 15, color: colors.secondary),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_compact(destination.reviewCount)} reviews',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _metadata(Destination destination) {
    return <String>[
      destination.province,
      destination.category,
      shortFee(destination.entryFee),
    ].join(' · ');
  }

  static String _compact(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    return thousands >= 10
        ? '${thousands.round()}k'
        : '${thousands.toStringAsFixed(1)}k';
  }
}

String shortFee(String entryFee) {
  final lower = entryFee.toLowerCase();
  if (lower.contains('free')) return 'Free';
  if (lower.contains('included')) return 'Included';

  final amount = RegExp(r'\$[\d.,]+').firstMatch(entryFee);
  return amount?.group(0) ?? entryFee;
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 62, height: 62, child: ColoredBox(color: color));
  }
}
