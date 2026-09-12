import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_textfield_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child, {required ThemeData theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AuthTextField — Material 3 theme tokens under AppTheme.dark', () {
    testWidgets(
      'cursorColor equals colorScheme.primary',
      (tester) async {
        final theme = AppTheme.dark;
        final ctrl = TextEditingController();

        await tester.pumpWidget(_pump(
          AuthTextField(controller: ctrl),
          theme: theme,
        ));

        final editableText =
            tester.widget<EditableText>(find.byType(EditableText));
        expect(
          editableText.cursorColor,
          theme.colorScheme.primary,
          reason: 'cursorColor must resolve to colorScheme.primary',
        );
      },
    );

    testWidgets(
      'hintStyle.color equals colorScheme.onSurfaceVariant',
      (tester) async {
        final theme = AppTheme.dark;
        final ctrl = TextEditingController();

        await tester.pumpWidget(_pump(
          AuthTextField(controller: ctrl, hintText: 'Enter email'),
          theme: theme,
        ));

        // TextFormField merges decoration with InputDecorationTheme via
        // applyDefaults; check the resulting TextField.decoration.
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(
          field.decoration?.hintStyle?.color,
          theme.colorScheme.onSurfaceVariant,
          reason:
              'hint text color must resolve to colorScheme.onSurfaceVariant',
        );
      },
    );
  });
}
