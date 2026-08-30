import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'quest_palette.dart';

/// Central Material 3 theme definition for the app.
class AppTheme {
  AppTheme._();

  static const Color seedColor = QuestPalette.violet;

  /// The quest experience is authored dark — the approved prototype has no
  /// light variant, and its whole progress language (mint done, pink here,
  /// amber ready) is tuned against a near-black backdrop. Following the system
  /// setting used to drop light-mode users into a seeded violet palette that
  /// resembled nothing in the design.
  static const ThemeMode themeMode = ThemeMode.dark;

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  );

  /// Written out rather than seeded. `ColorScheme.fromSeed` derives a
  /// violet-family tonal palette, so it cannot produce the prototype's mint,
  /// pink or amber at all — the accents that carry every progress cue.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: QuestPalette.violet,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF3B2A8C),
    onPrimaryContainer: Color(0xFFDCD2FF),
    secondary: QuestPalette.pink,
    onSecondary: Color(0xFF3A0B33),
    secondaryContainer: Color(0xFF4A2247),
    onSecondaryContainer: Color(0xFFFFD9F8),
    tertiary: QuestPalette.mint,
    onTertiary: QuestPalette.onMint,
    tertiaryContainer: Color(0xFF0A4936),
    onTertiaryContainer: Color(0xFF8FFFDA),
    error: Color(0xFFFF6B81),
    onError: Color(0xFF3A0710),
    errorContainer: Color(0xFF6E1424),
    onErrorContainer: Color(0xFFFFD9DE),
    surface: QuestPalette.ink,
    onSurface: Color(0xFFE9E6F0),
    onSurfaceVariant: QuestPalette.muted,
    surfaceContainerLowest: QuestPalette.night,
    surfaceContainerLow: Color(0xFF120D28),
    surfaceContainer: Color(0xFF1A1338),
    surfaceContainerHigh: QuestPalette.card,
    surfaceContainerHighest: Color(0xFF261C4F),
    outline: Color(0xFF554A7E),
    outlineVariant: Color(0xFF362C5C),
    inverseSurface: QuestPalette.cream,
    onInverseSurface: QuestPalette.ink,
    inversePrimary: Color(0xFF4B32B5),
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: kBodyFont,
      colorScheme: scheme,
      // The app shell paints one backdrop across the whole window, so pages
      // let it through instead of each painting its own flat rectangle. An
      // opaque scaffold would show as a hard-edged block wherever the window
      // is wider than the content column.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppTextStyles.apply(const TextTheme()),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2.0),
        ),
      ),
    );
  }
}
