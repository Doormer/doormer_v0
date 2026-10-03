import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_credentials_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(TextInput.restorePlatformInputControl);

  testWidgets(
    'credential fields cancel autofill when disposed before auth success',
    (tester) async {
      final textInput = _RecordingTextInputControl();
      TextInput.setInputControl(textInput);

      await tester.pumpWidget(_pump(
        _credentialsFields(
          passwordAutofillHints: const [AutofillHints.password],
        ),
      ));

      await tester.pumpWidget(_pump(const SizedBox.shrink()));
      await tester.pump();

      expect(textInput.autofillSaveRequests, [isFalse]);
    },
  );

  testWidgets('credential fields keep page-specific password hints',
      (tester) async {
    await tester.pumpWidget(_pump(
      _credentialsFields(
        passwordAutofillHints: const [AutofillHints.newPassword],
      ),
    ));

    final fields = tester.widgetList<TextField>(find.byType(TextField));

    expect(fields.first.autofillHints, const [AutofillHints.email]);
    expect(fields.last.autofillHints, const [AutofillHints.newPassword]);
  });
}

AuthCredentialsFields _credentialsFields({
  required Iterable<String> passwordAutofillHints,
}) {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocus = FocusNode();

  addTearDown(emailController.dispose);
  addTearDown(passwordController.dispose);
  addTearDown(passwordFocus.dispose);

  return AuthCredentialsFields(
    emailController: emailController,
    passwordController: passwordController,
    passwordFocus: passwordFocus,
    passwordAutofillHints: passwordAutofillHints,
  );
}

Widget _pump(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

class _RecordingTextInputControl with TextInputControl {
  final List<bool> autofillSaveRequests = [];

  @override
  void finishAutofillContext({bool shouldSave = true}) {
    autofillSaveRequests.add(shouldSave);
  }
}
