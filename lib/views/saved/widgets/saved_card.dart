import 'package:flutter/material.dart';

import '../../../models/destination.dart';
import '../../explore/widgets/destination_row.dart' show shortFee;

class SavedCard extends StatelessWidget {
  const SavedCard({
    required this.destination,
    required this.onTap,
    required this.onUnsave,
    super.key,
  });

  final Destination destination;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Cover(destination: destination, onUnsave: onUnsave),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    destination.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _RatingLine(destination: destination),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.destination, required this.onUnsave});

  final Destination destination;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: colors.surfaceContainerHighest);

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            destination.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: colors.surfaceContainerLowest,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onUnsave,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove ${destination.name} from saved',
                icon: Icon(Icons.favorite, color: colors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "4.8 ★ · Free"
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Text(
          destination.rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: 3),
        Icon(Icons.star_rounded, size: 13, color: theme.colorScheme.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '· ${shortFee(destination.entryFee)}',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
