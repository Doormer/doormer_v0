import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_textfield_web.dart';
import 'package:flutter/material.dart';

class AuthCredentialsFields extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final Iterable<String> passwordAutofillHints;
  final ValueChanged<String>? onPasswordSubmitted;
  final FormFieldValidator<String>? emailValidator;
  final FormFieldValidator<String>? passwordValidator;

  const AuthCredentialsFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocus,
    required this.passwordAutofillHints,
    this.onPasswordSubmitted,
    this.emailValidator,
    this.passwordValidator,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Email',
              style: textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 2),
          AuthTextField(
            label: 'Email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.email,
            ],
            onSubmitted: (_) => passwordFocus.requestFocus(),
            validator: emailValidator,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password',
              style: textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 2),
          AuthTextField(
            label: 'Password',
            controller: passwordController,
            isPassword: true,
            focusNode: passwordFocus,
            textInputAction: TextInputAction.done,
            autofillHints: passwordAutofillHints,
            onSubmitted: onPasswordSubmitted,
            validator: passwordValidator,
          ),
        ],
      ),
    );
  }
}
