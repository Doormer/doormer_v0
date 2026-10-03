import 'package:universal_html/html.dart' as html;
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/auth/presentation/widget/auth_credentials_fields.dart';
import 'package:doormer/src/features/auth/presentation/widget/google_signin_button.dart';
import 'package:doormer/src/features/auth/presentation/widget/signup_button.dart';
import 'package:doormer/src/features/auth/utils/auth_validators.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doormer/src/features/auth/presentation/utils/auth_autofill.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:toastification/toastification.dart';

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  State<LoginPageWeb> createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _login(BuildContext context, AuthBloc authBloc) {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text;
      final password = _passwordController.text;
      authBloc.add(LoginRequested(
        email: email,
        password: password,
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
                          AuthAutofill.finishOnAuthSuccess(state);
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
                          CustomToast.show(
                            context,
                            message: state.error,
                            type: ToastificationType.error,
                          );
                        }
                      },
                      builder: (context, state) {
                        final colorScheme = context.colorScheme;
                        final textTheme = context.textTheme;
                        return Container(
                          width: containerWidth,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: colorScheme.outlineVariant),
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
                                  'Welcome Back!',
                                  textAlign: TextAlign.center,
                                  style: textTheme.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                // Hint text below the heading
                                Text(
                                  'Log in to continue your journey.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: colorScheme.outlineVariant)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        'or log in with',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: colorScheme.outlineVariant)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                AuthCredentialsFields(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  passwordFocus: _passwordFocus,
                                  passwordAutofillHints: const [
                                    AutofillHints.password,
                                  ],
                                  onPasswordSubmitted: state is AuthLoading
                                      ? null
                                      : (_) => _login(context, authBloc),
                                  emailValidator: AuthValidators.validateEmail,
                                  passwordValidator:
                                      AuthValidators.validatePassword,
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
                                    Text(
                                      "Don't have an account? ",
                                      style: textTheme.bodyMedium,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        GoRouter.of(context).go('/auth/signup');
                                      },
                                      child: Text(
                                        "Sign Up",
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
