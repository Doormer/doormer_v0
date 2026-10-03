import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/services.dart';

class AuthAutofill {
  const AuthAutofill._();

  static void finishOnAuthSuccess(AuthState state) {
    if (state is AuthSuccess) {
      TextInput.finishAutofillContext();
    }
  }
}
