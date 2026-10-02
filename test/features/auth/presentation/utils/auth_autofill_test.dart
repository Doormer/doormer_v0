import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doormer/src/features/auth/presentation/utils/auth_autofill.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(TextInput.restorePlatformInputControl);

  test('finalizes autofill only for auth success', () {
    final textInput = _RecordingTextInputControl();
    TextInput.setInputControl(textInput);

    AuthAutofill.finishOnAuthSuccess(AuthLoading());
    AuthAutofill.finishOnAuthSuccess(AuthError('Rejected'));

    expect(textInput.autofillSaveRequests, isEmpty);

    AuthAutofill.finishOnAuthSuccess(AuthSuccess());

    expect(textInput.autofillSaveRequests, [isTrue]);
  });
}

class _RecordingTextInputControl with TextInputControl {
  final List<bool> autofillSaveRequests = [];

  @override
  void finishAutofillContext({bool shouldSave = true}) {
    autofillSaveRequests.add(shouldSave);
  }
}
