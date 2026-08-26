/// App-wide constants. Anything environment-specific (API base URLs, keys)
/// belongs in a config/env layer instead of here.
abstract final class AppConstants {
  static const String appName = 'Tourist Explorer';

  /// Default spacing unit; multiply for consistent gaps (8, 16, 24...).
  static const double spacing = 8.0;
}
