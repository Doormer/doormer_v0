import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child, {ThemeData? theme}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppButtonAtom variants', () {
    testWidgets('filled variant renders a FilledButton', (tester) async {
      await tester.pumpWidget(_pump(
        const AppButtonAtom(label: 'OK'),
      ));

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets(
        'accent variant under AppTheme.dark resolves background to tertiary '
        'and foreground to onTertiary', (tester) async {
      final darkTheme = AppTheme.dark;

      await tester.pumpWidget(_pump(
        const AppButtonAtom(
          label: 'Accent',
          variant: AppButtonVariant.accent,
        ),
        theme: darkTheme,
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style?.backgroundColor?.resolve({}),
        darkTheme.colorScheme.tertiary,
        reason: 'accent background should be colorScheme.tertiary',
      );
      expect(
        button.style?.foregroundColor?.resolve({}),
        darkTheme.colorScheme.onTertiary,
        reason: 'accent foreground should be colorScheme.onTertiary',
      );
    });
  });

  group('AppButtonAtom loading', () {
    Color paintedBackground(WidgetTester tester) {
      final material = tester.widget<Material>(find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ));
      return material.color!;
    }

    testWidgets(
        'accent keeps its tertiary background while loading so the '
        'onTertiary spinner stays visible', (tester) async {
      final darkTheme = AppTheme.dark;

      await tester.pumpWidget(_pump(
        AppButtonAtom(
          label: 'Submit',
          variant: AppButtonVariant.accent,
          isLoading: true,
          onPressed: () {},
        ),
        theme: darkTheme,
      ));

      expect(paintedBackground(tester), darkTheme.colorScheme.tertiary);
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.color, darkTheme.colorScheme.onTertiary);
    });

    testWidgets('filled keeps its primary background while loading',
        (tester) async {
      final darkTheme = AppTheme.dark;

      await tester.pumpWidget(_pump(
        const AppButtonAtom(label: 'Sign out', isLoading: true),
        theme: darkTheme,
      ));

      expect(paintedBackground(tester), darkTheme.colorScheme.primary);
    });

    testWidgets('a loading button cannot be pressed', (tester) async {
      var presses = 0;

      await tester.pumpWidget(_pump(
        AppButtonAtom(
          label: 'Submit',
          isLoading: true,
          onPressed: () => presses++,
        ),
      ));
      await tester.tap(find.byType(FilledButton));

      expect(presses, 0);
    });

    testWidgets('shows only the spinner when no loading label is given',
        (tester) async {
      await tester.pumpWidget(_pump(
        const AppButtonAtom(label: 'Submit', isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('shows the loading label next to the spinner', (tester) async {
      await tester.pumpWidget(_pump(
        const AppButtonAtom(
          label: 'Submit',
          loadingLabel: 'Solving your photo…',
          isLoading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Solving your photo…'), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('ignores the loading label when not loading', (tester) async {
      await tester.pumpWidget(_pump(
        const AppButtonAtom(
          label: 'Submit',
          loadingLabel: 'Solving your photo…',
        ),
      ));

      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Solving your photo…'), findsNothing);
    });
  });
}
