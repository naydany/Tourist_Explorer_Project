import 'package:latlong2/latlong.dart';

/// Tile source and camera defaults for the map screen.
abstract final class MapConfig {
  /// OpenStreetMap's public tile server. Its usage policy requires a real
  /// identifying user agent, hence [userAgentPackageName].
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Must match `applicationId` in android/app/build.gradle.kts.
  static const String userAgentPackageName =
      'com.example.tourist_explorer_project';

  /// Centred on Cambodia, zoomed out far enough to show the whole country.
  static const LatLng initialCentre = LatLng(12.5657, 104.9910);
  static const double initialZoom = 6.8;

  static const double minZoom = 5;
  static const double maxZoom = 17;
}
