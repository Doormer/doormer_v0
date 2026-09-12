import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seedColor is electric violet', () {
    expect(AppTheme.seedColor, const Color(0xFF6C4DFF));
  });

  test('the dark scheme carries the quest accents, which no seed can derive',
      () {
    final seeded = ColorScheme.fromSeed(
      seedColor: AppTheme.seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    );

    // The regression this guards: seeding from the violet produces a
    // violet-family tonal palette, so mint and amber cannot appear in it at
    // all. Every progress cue in the design is one of those two colours, which
    // is why the seeded build looked nothing like the approved prototype.
    expect(AppTheme.dark.colorScheme.tertiary, QuestPalette.mint);
    expect(AppTheme.dark.colorScheme.secondary, QuestPalette.pink);
    expect(AppTheme.dark.colorScheme.primary, QuestPalette.violet);
    expect(AppTheme.dark.colorScheme, isNot(seeded));
    expect(seeded.tertiary, isNot(QuestPalette.mint));
  });

  test('themeMode is dark, because the quest design has no light variant', () {
    expect(AppTheme.themeMode, ThemeMode.dark);
  });

  test('both schemes use the bundled reading face', () {
    expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, kBodyFont);
    expect(AppTheme.light.textTheme.bodyMedium?.fontFamily, kBodyFont);
  });

  group('AppTheme.light', () {
    late ThemeData theme;

    setUp(() => theme = AppTheme.light);

    test('does not register custom theme extensions', () {
      expect(theme.extensions, isEmpty);
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has Brightness.light', () {
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('primary is not black', () {
      expect(theme.colorScheme.primary, isNot(const Color(0xFF000000)));
    });

    test('bodyMedium color equals colorScheme.onSurface', () {
      expect(theme.textTheme.bodyMedium?.color, theme.colorScheme.onSurface);
    });
  });

  group('AppTheme.dark', () {
    late ThemeData theme;

    setUp(() => theme = AppTheme.dark);

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has Brightness.dark', () {
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('primary is not black', () {
      expect(theme.colorScheme.primary, isNot(const Color(0xFF000000)));
    });

    test('does not register custom theme extensions', () {
      expect(theme.extensions, isEmpty);
    });

    test('bodyMedium color equals colorScheme.onSurface', () {
      expect(theme.textTheme.bodyMedium?.color, theme.colorScheme.onSurface);
    });
  });
}
