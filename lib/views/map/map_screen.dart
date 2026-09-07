import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../models/destination.dart';
import '../../repositories/destination_repository.dart';
import '../../repositories/favorites_store.dart';
import 'widgets/map_peek_card.dart';
import 'widgets/map_pin.dart';

enum MapFilter {
  all('All pins'),
  saved('Saved only'),
  nearby('Nearby');

  const MapFilter(this.label);

  final String label;
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.repository,
    required this.favorites,
    super.key,
  });

  final DestinationRepository repository;
  final FavoritesStore favorites;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Cambodia, roughly centred, at a zoom that fits the country.
  static const LatLng _initialCentre = LatLng(12.5657, 104.9910);
  static const double _initialZoom = 6.8;

  final MapController _mapController = MapController();

  List<Destination> _destinations = <Destination>[];
  Destination? _selected;
  ApiException? _error;
  bool _isLoading = true;

  MapFilter _filter = MapFilter.all;

  bool _hasMoved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final destinations = await _fetch();
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _isLoading = false;
        _hasMoved = false;
        // Drop a selection that is no longer on the map.
        if (!destinations.any((d) => d.id == _selected?.id)) _selected = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<List<Destination>> _fetch() {
    final camera = _mapController.camera;
    final bounds = camera.visibleBounds;

    return switch (_filter) {
      MapFilter.nearby => widget.repository.getNearby(
        latitude: camera.center.latitude,
        longitude: camera.center.longitude,
        radiusKm: 100,
        limit: 20,
      ),
      MapFilter.all || MapFilter.saved => widget.repository.getInBounds(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
      ),
    };
  }

  List<Destination> get _visible {
    if (_filter != MapFilter.saved) return _destinations;
    return _destinations
        .where((d) => widget.favorites.contains(d.id))
        .toList(growable: false);
  }

  void _onFilterChanged(MapFilter filter) {
    if (filter == _filter) return;
    // Captured before setState overwrites it: leaving Nearby needs a refetch
    // too, since it reads a different endpoint than the viewport search.
    final previous = _filter;
    setState(() {
      _filter = filter;
      _selected = null;
    });
    if (filter == MapFilter.nearby || previous == MapFilter.nearby) _load();
  }

  void _onSelected(Destination destination) {
    setState(() => _selected = destination);
    _mapController.move(
      LatLng(destination.latitude, destination.longitude),
      _mapController.camera.zoom,
    );
  }

  void _openDetail(Destination destination) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.destination, arguments: destination.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildMap(),
          _TopControls(
            filter: _filter,
            onFilterChanged: _onFilterChanged,
            onSearchArea: _hasMoved ? _load : null,
            isLoading: _isLoading,
          ),
          if (_error != null)
            _MapMessage(text: _error!.message, onRetry: _load)
          else if (!_isLoading && _visible.isEmpty)
            _MapMessage(text: _emptyMessage, onRetry: null),
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: MapPeekCard(
                destination: _selected!,
                onOpen: () => _openDetail(_selected!),
              ),
            ),
        ],
      ),
    );
  }

  String get _emptyMessage {
    return switch (_filter) {
      MapFilter.saved => 'None of your saved places are in view.',
      MapFilter.nearby => 'Nothing within 100 km of here.',
      MapFilter.all => 'No destinations in this area.',
    };
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCentre,
        initialZoom: _initialZoom,
        minZoom: 5,
        maxZoom: 17,
        onTap: (tapPosition, point) => setState(() => _selected = null),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && !_hasMoved) setState(() => _hasMoved = true);
        },
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.tourist_explorer_project',
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        MarkerLayer(markers: _markers()),
      ],
    );
  }

  List<Marker> _markers() {
    return <Marker>[
      for (final destination in _visible)
        Marker(
          point: LatLng(destination.latitude, destination.longitude),
          width: MapPin.width,
          height: MapPin.height,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => _onSelected(destination),
            child: MapPin(isSelected: destination.id == _selected?.id),
          ),
        ),
    ];
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchArea,
    required this.isLoading,
  });

  final MapFilter filter;
  final ValueChanged<MapFilter> onFilterChanged;

  final VoidCallback? onSearchArea;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: _SearchArea(onPressed: onSearchArea, isLoading: isLoading),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                for (final value in MapFilter.values) ...<Widget>[
                  _FilterChip(
                    label: value.label,
                    selected: value == filter,
                    onTap: () => onFilterChanged(value),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchArea extends StatelessWidget {
  const _SearchArea({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: <Widget>[
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.search,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 12),
              Text(
                isLoading ? 'Loading…' : 'Search this area',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerLowest,
      shape: const StadiumBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.text, required this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.center,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                text,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
