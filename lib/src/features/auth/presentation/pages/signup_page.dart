import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/presentation/widget/signup_button.dart';
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                        32.0), // Outer padding around the container
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthSuccess) {
                          final sessionState =
                              context.read<GlobalSessionBloc>().state;
                          if (sessionState is SessionActiveState) {
                            final router = GoRouter.of(context);
                            router.go('/auth/registration');
                          }
                        }
                        if (state is AuthFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.error,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return Container(
                          width: 400, // Fixed width for phone browsers
                          padding: const EdgeInsets.all(24.0), // Inner padding
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borders),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Heading at the top center
                                const Text(
                                  'Create an account',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                // Hint text below the heading
                                Text(
                                  'Sign up to get started with doormer',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.hintText,
                                ),
                                const SizedBox(height: 24),
                                // Google button at the top
                                const Center(child: GoogleSignInButton()),
                                const SizedBox(height: 24),
                                // Divider row
                                const Row(
                                  children: [
                                    Expanded(
                                        child: Divider(color: Colors.grey)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text('or sign up with',
                                          style:
                                              TextStyle(color: Colors.black54)),
                                    ),
                                    Expanded(
                                        child: Divider(color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Email text field
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
                                // Password text field
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
                                // Sign up button
                                SizedBox(
                                  width: double.infinity,
                                  child: SignUpButton(
                                    isLoading: state is AuthLoading,
                                    onPressed: state is AuthLoading
                                        ? null
                                        : () => _signUp(context, authBloc),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
