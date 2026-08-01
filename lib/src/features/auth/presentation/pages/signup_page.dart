import 'package:universal_html/html.dart' as html;
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/presentation/widget/agreement_text_widget.dart';
import 'package:doormer/src/features/auth/presentation/widget/signup_button.dart';
import 'package:doormer/src/features/auth/utils/auth_validators.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_textfield_web.dart';
import 'package:doormer/src/features/auth/presentation/widget/google_signin_button.dart';
import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:toastification/toastification.dart';

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
            // Determine if the device is a phone by checking the user agent.
            bool isPhone;
            try {
              final userAgent = html.window.navigator.userAgent.toLowerCase();
              isPhone = userAgent.contains('iphone') ||
                  userAgent.contains('android') ||
                  userAgent.contains('mobile');
            } catch (e) {
              // Fallback: use constraints as a heuristic.
              isPhone = constraints.maxWidth < 400;
            }
            // Set container and Google button widths based on device type.
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

                        if (state is AuthError) {
                          final errorMsg = state.error.toString().toLowerCase();
                          if (errorMsg.contains('user is already registered')) {
                            CustomToast.show(
                              context,
                              message:
                                  'An account with this email already exists. Redirecting to login...',
                              type: ToastificationType.warning,
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              router.go('/auth/login');
                            });
                          } else {
                            CustomToast.show(
                              context,
                              message: 'Sign Up Failed.',
                              type: ToastificationType.error,
                            );
                          }
                        }
                      },
                      builder: (context, state) {
                        final colorScheme = context.colorScheme;
                        final textTheme = context.textTheme;
                        return Container(
                          width: containerWidth,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Heading at the top center
                                Text(
                                  'Join Today!',
                                  textAlign: TextAlign.center,
                                  style: textTheme.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                // Hint text below the heading
                                Text(
                                  'Sign up to get started',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Align(
                                  alignment: Alignment.center,
                                  child: AgreementTextWidget(),
                                ),
                                const SizedBox(height: 24),
                                // Google Sign-In button with dynamic minimum width.
                                Center(
                                  child: GoogleSignInButton(
                                    minimumWidth: googleButtonMinWidth,
                                    buttonText: GSIButtonText.signupWith,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Divider row
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(color: colorScheme.outlineVariant)),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'or sign up with',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(color: colorScheme.outlineVariant)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Email text field
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Email',
                                    style: textTheme.bodyMedium,
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
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Password',
                                    style: textTheme.bodyMedium,
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
                                const SizedBox(height: 24),
                                // Login redirect
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: textTheme.bodyMedium,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        GoRouter.of(context).go('/auth/login');
                                      },
                                      child: Text(
                                        "Login",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: colorScheme.primary,
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
