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
}
