import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // Size/weight tokens — no fixed foreground colors; consume via Theme or
  // rely on inherited DefaultTextStyle for color resolution.
  static const TextStyle displayLarge =
      TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold);

  static const TextStyle displayMedium =
      TextStyle(fontSize: 30.0, fontWeight: FontWeight.w600);

  static const TextStyle headingLarge =
      TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold);

  static const TextStyle headingMedium =
      TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600);

  static const TextStyle titleLarge =
      TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);

  static const TextStyle titleMedium =
      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);

  static const TextStyle bodyLarge =
      TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal);

  static const TextStyle bodyMedium =
      TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal);

  static const TextStyle bodySmall =
      TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal);

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  // Widget-specific tokens (no color — resolved by theme or parent).
  static const TextStyle hintText =
      TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal);

  static const TextStyle selectedText =
      TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal);

  static const TextStyle inputText =
      TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal);

  static const TextStyle buttonText =
      TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal);

  /// Overlays font sizes, weights and letter-spacing from [AppTextStyles] onto
  /// [base] without touching its foreground colors.
  ///
  /// The [ThemeData] merge step will supply the correct [ColorScheme]-derived
  /// colors, so callers must not pass a pre-colored base expecting to preserve
  /// those colors through the merge.
  static TextTheme apply(TextTheme base) => base.copyWith(
        displayLarge:
            const TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
        displayMedium:
            const TextStyle(fontSize: 30.0, fontWeight: FontWeight.w600),
        headlineLarge:
            const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        headlineMedium:
            const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600),
        titleLarge:
            const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        titleMedium:
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(fontSize: 16.0),
        bodyMedium: const TextStyle(fontSize: 14.0),
        bodySmall: const TextStyle(fontSize: 12.0),
        labelSmall: const TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
        labelLarge: const TextStyle(fontSize: 14.0),
      );
}
