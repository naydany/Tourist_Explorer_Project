import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/destination.dart';
import '../../models/opening_hours.dart';
import '../../repositories/destination_repository.dart';
import '../../stores/favorites_store.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({
    required this.destinationId,
    required this.repository,
    required this.favorites,
    super.key,
  });

  final int destinationId;
  final DestinationRepository repository;
  final FavoritesStore favorites;

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  Destination? _destination;
  ApiException? _error;

  /// Null while in flight; empty once we know there is nothing to show.
  List<Destination>? _nearby;

  @override
  void initState() {
    super.initState();
    _destination = widget.repository.peek(widget.destinationId);
    if (_destination == null) _load();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    try {
      final nearby = await widget.repository.getNearbyTo(widget.destinationId);
      if (!mounted) return;
      setState(() {
        _nearby = nearby
            .where((d) => d.id != widget.destinationId)
            .toList(growable: false);
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _nearby = const <Destination>[]);
    }
  }

  void _openNearby(Destination destination) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailScreen(
          destinationId: destination.id,
          repository: widget.repository,
          favorites: widget.favorites,
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final destination = await widget.repository.getById(widget.destinationId);
      if (!mounted) return;
      setState(() => _destination = destination);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _copyCoordinates(Destination destination) async {
    final coordinates = '${destination.latitude}, ${destination.longitude}';
    await Clipboard.setData(ClipboardData(text: coordinates));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Coordinates copied: $coordinates')));
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    final error = _error;

    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: _DetailError(error: error, onRetry: _load),
      );
    }

    if (destination == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: widget.favorites,
      builder: (context, _) {
        final isFavorite = widget.favorites.contains(destination.id);

        return Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _Header(
                  destination: destination,
                  isFavorite: isFavorite,
                  onFavoriteToggle: () => widget.favorites.toggle(destination),
                ),
              ),
              SliverToBoxAdapter(
                child: _Body(
                  destination: destination,
                  nearby: _nearby,
                  onNearbySelected: _openNearby,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _ActionBar(
            isFavorite: isFavorite,
            onFavoriteToggle: () => widget.favorites.toggle(destination),
            onDirections: () => _copyCoordinates(destination),
          ),
        );
      },
    );
  }
}

class _ReadableWidth extends StatelessWidget {
  const _ReadableWidth({required this.child});

  static const double maxWidth = 560;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.destination,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Destination destination;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            destination.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(color: colors.surfaceContainerHighest);
            },
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(color: colors.surfaceContainerHighest);
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x73000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xA6000000),
                ],
                stops: <double>[0, 0.32, 0.52, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _RoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _RoundButton(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite ? colors.error : null,
                        tooltip: isFavorite ? 'Remove from saved' : 'Save',
                        onPressed: onFavoriteToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  destination.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    shadows: const <Shadow>[
                      Shadow(blurRadius: 14, color: Color(0xB3000000)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        destination.address,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          shadows: const <Shadow>[
                            Shadow(blurRadius: 10, color: Color(0xAA000000)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.destination,
    required this.nearby,
    required this.onNearbySelected,
  });

  final Destination destination;
  final List<Destination>? nearby;
  final ValueChanged<Destination> onNearbySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Transform.translate(
      offset: const Offset(0, -36),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 44),
        child: _ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _FactsPanel(destination: destination),
              const SizedBox(height: 26),
              Row(
                children: <Widget>[
                  Text('ABOUT', style: theme.textTheme.labelSmall),
                  const SizedBox(width: 12),
                  const Expanded(child: Divider(height: 1)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                destination.longDescription,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              _Gallery(images: destination.gallery),
              _TagWrap(tags: destination.tags),
              const SizedBox(height: 16),
              _NearbySection(
                destinations: nearby,
                onSelected: onNearbySelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Other places worth visiting around this one. Hidden entirely while loading
/// or when the API has nothing to suggest, so it never leaves a blank gap.
class _NearbySection extends StatelessWidget {
  const _NearbySection({required this.destinations, required this.onSelected});

  static const double _cardWidth = 168;
  static const double _imageHeight = 96;

  final List<Destination>? destinations;
  final ValueChanged<Destination> onSelected;

  @override
  Widget build(BuildContext context) {
    final nearby = destinations;
    if (nearby == null || nearby.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Text('NEARBY', style: theme.textTheme.labelSmall),
            const SizedBox(width: 12),
            const Expanded(child: Divider(height: 1)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nearby.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _NearbyCard(
                destination: nearby[index],
                width: _cardWidth,
                imageHeight: _imageHeight,
                onTap: () => onSelected(nearby[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.destination,
    required this.width,
    required this.imageHeight,
    required this.onTap,
  });

  final Destination destination;
  final double width;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SizedBox(width: width, height: imageHeight),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                destination.imageUrl,
                width: width,
                height: imageHeight,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              destination.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  destination.rating.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FactsPanel extends StatelessWidget {
  const _FactsPanel({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = readOpeningStatus(destination.openingHours);
    final (price, unit) = _splitFee(destination.entryFee);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.forest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ENTRY FEE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              price,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontSize: price.length > 12 ? 19 : 26,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unit != null) ...<Widget>[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                unit,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (status != OpeningStatus.unknown) ...<Widget>[
                  const SizedBox(width: 12),
                  _StatusPill(isOpen: status == OpeningStatus.open),
                ],
              ],
            ),
          ),
          const _Perforation(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Fact(label: 'HOURS', value: destination.openingHours),
                _Fact(label: 'BEST TIME', value: destination.bestTimeToVisit),
                _Fact(
                  label: 'RATING',
                  value: '${destination.rating} ★',
                  detail: '${_thousands(destination.reviewCount)} reviews',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    final notch = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _DashedLine(),
          ),
          Positioned(left: -10, child: _Notch(color: notch)),
          Positioned(right: -10, child: _Notch(color: notch)),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gapWidth = 5.0;
        final count = (constraints.maxWidth / (dashWidth + gapWidth)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            count,
            (_) => const SizedBox(
              width: dashWidth,
              height: 1,
              child: ColoredBox(color: Colors.white24),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOpen ? AppTheme.star : Colors.white38;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              isOpen ? 'Open now' : 'Closed now',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isOpen ? AppTheme.star : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                detail!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('GALLERY', style: theme.textTheme.labelSmall),
            const SizedBox(width: 12),
            const Expanded(child: Divider(height: 1)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  images[index],
                  width: 130,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      width: 130,
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: 130,
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final tag in tags)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(tag.toUpperCase(), style: theme.textTheme.labelSmall),
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onDirections,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: _ReadableWidth(
          child: Row(
            children: <Widget>[
              Material(
                color: colors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: InkWell(
                  onTap: onFavoriteToggle,
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 58,
                    height: 56,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: colors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: onDirections,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Get directions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 20,
        icon: Icon(icon, color: color ?? colors.onSurface),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.error, required this.onRetry});

  final ApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (IconData icon, String headline) = switch (error) {
      NetworkException() => (Icons.wifi_off_rounded, 'No connection'),
      ApiStatusException(isNotFound: true) => (
        Icons.search_off_rounded,
        'Destination not found',
      ),
      ApiStatusException() => (Icons.cloud_off_rounded, 'Server problem'),
      ParseException() => (Icons.error_outline_rounded, 'Unexpected response'),
    };

    return Padding(
      padding: const EdgeInsets.all(40),
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

(String price, String? unit) _splitFee(String entryFee) {
  final match = RegExp(
    r'^\s*(\$?[\d.,]+|free)\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(entryFee);
  if (match == null) return (entryFee, null);

  final remainder = match.group(2)?.trim();
  return (
    match.group(1)!,
    remainder == null || remainder.isEmpty ? null : remainder,
  );
}

String _thousands(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match.group(1)},',
  );
}
