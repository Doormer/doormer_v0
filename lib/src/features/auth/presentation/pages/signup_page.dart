import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/utils/auth_validators.dart';
import 'package:flutter/material.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_textfield_web.dart';
import 'package:doormer/src/features/auth/presentation/widget/google_signin_button.dart';
import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignUpPageWeb extends StatelessWidget {
  SignUpPageWeb({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _signUp(BuildContext context, AuthBloc authBloc) {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text;
      final password = _passwordController.text;
      AppLogger.info('Dispatching SignupRequested event with email: $email');
      authBloc.add(SignupRequested(
        email: email,
        password: password,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = serviceLocator<AuthBloc>();

    return BlocProvider<AuthBloc>(
      create: (_) => authBloc,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                final sessionState = context.read<GlobalSessionBloc>().state;
                if (sessionState is SessionActiveState) {
                  final router = GoRouter.of(context);
                  router.go('/auth/registration');
                }
              }
            },
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title text (left-aligned)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create your account.',
                        textAlign: TextAlign.left,
                        style: AppTextStyles.displayMedium,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email label (left-aligned)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AuthTextField(
                      controller: _emailController,
                      obscureText: false,
                      validator: AuthValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    // Password label (left-aligned)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AuthTextField(
                      controller: _passwordController,
                      obscureText: true,
                      validator: AuthValidators.validatePassword,
                    ),
                    const SizedBox(height: 32),
                    // Centered Google sign-in button
                    const Center(child: GoogleSignInButton()),
                    // If there's an AuthFailure, show the error message (centered)
                    if (state is AuthFailure)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Center(
                          child: Text(
                            state.error,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Centered Sign Up button
                    Center(
                      child: ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () => _signUp(context, authBloc),
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.surface,
                              )
                            : const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
