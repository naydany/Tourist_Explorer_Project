import 'package:flutter/material.dart';

/// Single source of truth for colors, typography and component styling.
/// Widgets should read from `Theme.of(context)` rather than hardcoding values.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF00796B);

  // Light mode.
  static const Color cream = Color(0xFFF4F2E7); // page background
  static const Color ink = Color(0xFF14261D); // primary text
  static const Color forest = Color(0xFF0F3D2E); // brand green
  static const Color sage = Color(0xFF6B7A70); // secondary text
  static const Color card = Color(0xFFFFFFFF); // card surfaces
  static const Color line = Color(0xFFE2DED0); // hairlines, chip borders
  static const Color placeholder = Color(0xFFE7E3D6); // image placeholder

  // Dark mode.
  static const Color darkSurface = Color(0xFF121914);
  static const Color darkCard = Color(0xFF1B231C);
  static const Color darkInk = Color(0xFFEDEFE8);
  static const Color darkSage = Color(0xFF9AA79D);
  static const Color darkLine = Color(0xFF2C352D);
  static const Color darkPlaceholder = Color(0xFF262E27);
  static const Color darkForest = Color(0xFF7FC7A4);

  /// Rating stars and tag borders. Deliberately the same in both modes.
  static const Color star = Color(0xFFE8A33D);

  /// The favourite heart when active. Also used as the error color.
  static const Color favorite = Color(0xFFD6336C);

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: forest,
      onPrimary: Colors.white,
      secondary: star,
      onSecondary: ink,
      surface: cream,
      onSurface: ink,
      onSurfaceVariant: sage,
      // Cards, the search field and chips sit on this.
      surfaceContainerLowest: card,
      // Fill shown while an image loads or fails.
      surfaceContainerHighest: placeholder,
      outlineVariant: line,
      error: favorite,
    );

    return _base(colorScheme);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: darkForest,
      onPrimary: darkSurface,
      secondary: star,
      onSecondary: darkSurface,
      surface: darkSurface,
      onSurface: darkInk,
      onSurfaceVariant: darkSage,
      surfaceContainerLowest: darkCard,
      surfaceContainerHighest: darkPlaceholder,
      outlineVariant: darkLine,
      error: favorite,
    );

    return _base(colorScheme);
  }

  static ThemeData _base(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      // The search field: pill shaped, filled, no visible border.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIconColor: colorScheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: _textTheme(colorScheme),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return TextTheme(
      // "Where to today?"
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      // Card titles.
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      // Card descriptions.
      bodyMedium: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
      // Location line, weather line, entry fee.
      bodySmall: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      // Filter chip labels.
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      // Section headers such as "POPULAR THIS WEEK", and tag chips.
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
