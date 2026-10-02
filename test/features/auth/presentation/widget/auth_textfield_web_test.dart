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
          AuthTextField(label: 'Email', controller: ctrl),
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
          AuthTextField(
            label: 'Email',
            controller: ctrl,
            hintText: 'Enter email',
          ),
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

  testWidgets('a password field toggles visibility', (tester) async {
    await tester.pumpWidget(_pump(
      AuthTextField(
        label: 'Password',
        controller: TextEditingController(),
        isPassword: true,
      ),
      theme: AppTheme.light,
    ));

    EditableText editable() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(editable().obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('an error clears as soon as the field is edited', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_pump(
      Form(
        key: formKey,
        child: AuthTextField(
          label: 'Email',
          controller: TextEditingController(),
          validator: (v) => (v ?? '').contains('@') ? null : 'Enter an email',
        ),
      ),
      theme: AppTheme.light,
    ));

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Enter an email'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'a@b.co');
    await tester.pump();
    expect(find.text('Enter an email'), findsNothing);
  });

  testWidgets('the field is named for screen readers', (tester) async {
    await tester.pumpWidget(_pump(
      AuthTextField(label: 'Email', controller: TextEditingController()),
      theme: AppTheme.light,
    ));
    expect(find.bySemanticsLabel('Email'), findsOneWidget);
  });
}
