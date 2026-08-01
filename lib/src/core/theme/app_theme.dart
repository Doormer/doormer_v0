import 'package:flutter/material.dart';

import 'app_text_styles.dart';

/// Central Material 3 theme definition for the app.
class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF6C4DFF);
  static const ThemeMode themeMode = ThemeMode.system;

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Helvetica',
      colorScheme: scheme,
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
