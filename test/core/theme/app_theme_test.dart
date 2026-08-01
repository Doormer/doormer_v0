import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seedColor is electric violet', () {
    expect(AppTheme.seedColor, const Color(0xFF6C4DFF));
  });

  test('schemes use the content variant for violet and magenta roles', () {
    final expectedLight = ColorScheme.fromSeed(
      seedColor: AppTheme.seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    );
    final expectedDark = ColorScheme.fromSeed(
      seedColor: AppTheme.seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    );

    expect(AppTheme.light.colorScheme, expectedLight);
    expect(AppTheme.dark.colorScheme, expectedDark);
    expect(AppTheme.light.colorScheme.tertiary, const Color(0xFF9B019A));
    expect(AppTheme.dark.colorScheme.tertiary, const Color(0xFFFFABF3));
  });

  test('themeMode is ThemeMode.system', () {
    expect(AppTheme.themeMode, ThemeMode.system);
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
