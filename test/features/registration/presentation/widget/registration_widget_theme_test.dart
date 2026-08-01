// TDD tests for Task 5 – Material 3 migration of registration widgets.
//
// Tests verify:
//  1. MultiSelectBottomSheet: nullable badgeColor / circularAvatarTextColor
//     default to primaryContainer / onPrimaryContainer from the active theme.
//  2. Explicit overrides are still honoured.
//  3. CategorySelectionCard: nullable borderColor defaults to outlineVariant.
//  4. SelectionBottomSheet: nullable mainColor defaults to primary for the
//     CircleAvatar selection-indicator badge.
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/registration/presentation/widget/category_selection_card.dart';
import 'package:doormer/src/features/registration/presentation/widget/priority_multi_select_bottom_sheet.dart';
import 'package:doormer/src/features/registration/presentation/widget/selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in a [MaterialApp] with the given [theme].
Widget _pump(Widget child, {required ThemeData theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

/// Returns the first [CircleAvatar] found in the widget tree.
CircleAvatar _firstAvatar(WidgetTester tester) =>
    tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);

// ---------------------------------------------------------------------------
// MultiSelectBottomSheet
// ---------------------------------------------------------------------------

void main() {
  group('MultiSelectBottomSheet – nullable color defaults', () {
    testWidgets(
        'badgeColor defaults to primaryContainer under dark theme when null',
        (tester) async {
      final theme = AppTheme.dark;

      await tester.pumpWidget(_pump(
        const SizedBox(
          height: 600,
          child: MultiSelectBottomSheet(
            options: ['Option A', 'Option B'],
            initialSelected: ['Option A'],
            maxSelection: 3,
          ),
        ),
        theme: theme,
      ));

      expect(
        _firstAvatar(tester).backgroundColor,
        theme.colorScheme.primaryContainer,
      );
    });

    testWidgets(
        'circularAvatarTextColor defaults to onPrimaryContainer under dark '
        'theme when null', (tester) async {
      final theme = AppTheme.dark;

      await tester.pumpWidget(_pump(
        const SizedBox(
          height: 600,
          child: MultiSelectBottomSheet(
            options: ['Option A', 'Option B'],
            initialSelected: ['Option A'],
            maxSelection: 3,
          ),
        ),
        theme: theme,
      ));

      final badge = _firstAvatar(tester);
      final labelText = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(badge),
          matching: find.byType(Text),
        ),
      );
      expect(labelText.style?.color, theme.colorScheme.onPrimaryContainer);
    });

    testWidgets('explicit badgeColor is honoured over theme default',
        (tester) async {
      const override = Color(0xFFFF4444);

      await tester.pumpWidget(_pump(
        const SizedBox(
          height: 600,
          child: MultiSelectBottomSheet(
            options: ['Option A', 'Option B'],
            initialSelected: ['Option A'],
            maxSelection: 3,
            badgeColor: override,
          ),
        ),
        theme: AppTheme.light,
      ));

      expect(_firstAvatar(tester).backgroundColor, override);
    });

    testWidgets(
        'badgeColor defaults to primaryContainer under light theme when null',
        (tester) async {
      final theme = AppTheme.light;

      await tester.pumpWidget(_pump(
        const SizedBox(
          height: 600,
          child: MultiSelectBottomSheet(
            options: ['Option A'],
            initialSelected: ['Option A'],
            maxSelection: 3,
          ),
        ),
        theme: theme,
      ));

      expect(
        _firstAvatar(tester).backgroundColor,
        theme.colorScheme.primaryContainer,
      );
    });
  });

  // -------------------------------------------------------------------------
  // CategorySelectionCard
  // -------------------------------------------------------------------------

  group('CategorySelectionCard – nullable borderColor default', () {
    testWidgets(
        'outer container border defaults to outlineVariant when borderColor is null',
        (tester) async {
      final theme = AppTheme.light;
      final expectedColor = theme.colorScheme.outlineVariant;

      await tester.pumpWidget(_pump(
        const SizedBox(
          width: 400,
          child: CategorySelectionCard(
            title: 'Roles',
            description: 'Choose your top 3 roles',
            options: ['Dev', 'Design', 'PM'],
          ),
        ),
        theme: theme,
      ));

      final containerWithBorder = find.byWidgetPredicate((w) {
        if (w is Container) {
          final dec = w.decoration;
          if (dec is BoxDecoration && dec.border != null) {
            final b = dec.border as Border?;
            return b?.top.color == expectedColor;
          }
        }
        return false;
      });

      expect(containerWithBorder, findsAtLeast(1));
    });

    testWidgets(
        'outer container border defaults to outlineVariant in dark theme when borderColor is null',
        (tester) async {
      final theme = AppTheme.dark;
      final expectedColor = theme.colorScheme.outlineVariant;

      await tester.pumpWidget(_pump(
        const SizedBox(
          width: 400,
          child: CategorySelectionCard(
            title: 'Industry',
            description: 'Choose your top 3 industries',
            options: ['Tech', 'Finance'],
          ),
        ),
        theme: theme,
      ));

      final containerWithBorder = find.byWidgetPredicate((w) {
        if (w is Container) {
          final dec = w.decoration;
          if (dec is BoxDecoration && dec.border != null) {
            final b = dec.border as Border?;
            return b?.top.color == expectedColor;
          }
        }
        return false;
      });

      expect(containerWithBorder, findsAtLeast(1));
    });

    testWidgets('explicit borderColor is honoured over theme default',
        (tester) async {
      const override = Color(0xFF00AA00);

      await tester.pumpWidget(_pump(
        const SizedBox(
          width: 400,
          child: CategorySelectionCard(
            title: 'Roles',
            description: 'Choose your top 3 roles',
            options: ['Dev'],
            borderColor: override,
          ),
        ),
        theme: AppTheme.light,
      ));

      final containerWithBorder = find.byWidgetPredicate((w) {
        if (w is Container) {
          final dec = w.decoration;
          if (dec is BoxDecoration && dec.border != null) {
            final b = dec.border as Border?;
            return b?.top.color == override;
          }
        }
        return false;
      });

      expect(containerWithBorder, findsAtLeast(1));
    });
  });

  // -------------------------------------------------------------------------
  // SelectionBottomSheet – selection-indicator badge
  // -------------------------------------------------------------------------

  group('SelectionBottomSheet – nullable mainColor default', () {
    testWidgets(
        'selection-indicator badge defaults to primaryContainer when mainColor '
        'is null', (tester) async {
      final theme = AppTheme.dark;

      await tester.pumpWidget(_pump(
        SelectionBottomSheet(
          options: const ['Alpha', 'Beta', 'Gamma'],
          initialSelection: const ['Alpha'],
          onSubmit: (_) {},
          onClose: () {},
        ),
        theme: theme,
      ));

      expect(
        _firstAvatar(tester).backgroundColor,
        theme.colorScheme.primaryContainer,
      );
    });

    testWidgets('explicit mainColor is honoured for selection indicator',
        (tester) async {
      const override = Color(0xFFAA0000);

      await tester.pumpWidget(_pump(
        SelectionBottomSheet(
          options: const ['Alpha', 'Beta'],
          initialSelection: const ['Alpha'],
          onSubmit: (_) {},
          onClose: () {},
          mainColor: override,
        ),
        theme: AppTheme.light,
      ));

      expect(_firstAvatar(tester).backgroundColor, override);
    });
  });
}
