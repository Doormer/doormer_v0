import 'dart:html' as html;
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_textfield_web.dart';
import 'package:doormer/src/features/auth/presentation/widget/google_signin_button.dart';
import 'package:doormer/src/features/auth/presentation/widget/signup_button.dart';
import 'package:doormer/src/features/auth/utils/auth_validators.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:toastification/toastification.dart';

class LoginPageWeb extends StatelessWidget {
  LoginPageWeb({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _login(BuildContext context, AuthBloc authBloc) {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text;
      final password = _passwordController.text;
      AppLogger.info('Dispatching LoginRequested event with email: $email');
      authBloc.add(LoginRequested(
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
            // Determine if the device is a phone by checking the user agent.
            bool isPhone;
            try {
              final userAgent = html.window.navigator.userAgent.toLowerCase();
              isPhone = userAgent.contains('iphone') ||
                  userAgent.contains('android') ||
                  userAgent.contains('mobile');
            } catch (e) {
              // Fallback heuristic using screen width.
              isPhone = constraints.maxWidth < 400;
            }
            // Set widths based on device type.
            final containerWidth = isPhone ? 320.0 : 400.0;
            final googleButtonMinWidth = isPhone ? 320.0 - 50 : 400.0 - 50;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        final router = GoRouter.of(context);

                        if (state is AuthSuccess) {
                          final sessionState =
                              context.read<GlobalSessionBloc>().state;
                          if (sessionState is SessionActiveState) {
                            final user = sessionState.user;
                            if (user.userRegistrationStatus == 0) {
                              router.go('/auth/registration');
                            } else {
                              router.go('/auth/registration-complete');
                            }
                          }
                        }

                        if (state is AuthFailure) {
                          final errorMsg = state.error.toString().toLowerCase();
                          if (errorMsg.contains('wrong email or password')) {
                            CustomToast.show(
                              context,
                              message: 'Wrong Email Or Password',
                              type: ToastificationType.error,
                            );
                          } else {
                            CustomToast.show(
                              context,
                              message: 'Login Failed.',
                              type: ToastificationType.error,
                            );
                          }
                        }
                      },
                      builder: (context, state) {
                        return Container(
                          width: containerWidth,
                          padding: const EdgeInsets.all(24.0),
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
                                  'Welcome Back!',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                // Hint text below the heading
                                Text(
                                  'Log in to continue your journey.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.hintText,
                                ),
                                const SizedBox(height: 24),
                                // Google Sign-In button with dynamic minimum width.
                                Center(
                                  child: GoogleSignInButton(
                                    minimumWidth: googleButtonMinWidth,
                                    buttonText: GSIButtonText.continueWith,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Divider row
                                const Row(
                                  children: [
                                    Expanded(
                                        child: Divider(color: Colors.grey)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text('or log in with',
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
                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  child: SignUpButton(
                                    buttonText: 'Login',
                                    isLoading: state is AuthLoading,
                                    onPressed: state is AuthLoading
                                        ? null
                                        : () => _login(context, authBloc),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Sign up redirect
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        GoRouter.of(context).go('/auth/signup');
                                      },
                                      child: Text(
                                        "Sign Up",
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
