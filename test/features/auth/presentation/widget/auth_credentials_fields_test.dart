import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_credentials_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'credential fields cancel autofill when disposed before auth success',
    (tester) async {
      await tester.pumpWidget(_pump(
        AuthCredentialsFields(
          emailController: TextEditingController(),
          passwordController: TextEditingController(),
          passwordFocus: FocusNode(),
          passwordAutofillHints: const [AutofillHints.password],
        ),
      ));

      final group = tester.widget<AutofillGroup>(find.byType(AutofillGroup));

      expect(group.onDisposeAction, AutofillContextAction.cancel);
    },
  );

  testWidgets('credential fields keep page-specific password hints',
      (tester) async {
    await tester.pumpWidget(_pump(
      AuthCredentialsFields(
        emailController: TextEditingController(),
        passwordController: TextEditingController(),
        passwordFocus: FocusNode(),
        passwordAutofillHints: const [AutofillHints.newPassword],
      ),
    ));

    final fields = tester.widgetList<TextField>(find.byType(TextField));

    expect(fields.first.autofillHints, const [AutofillHints.email]);
    expect(fields.last.autofillHints, const [AutofillHints.newPassword]);
  });
}

Widget _pump(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}
