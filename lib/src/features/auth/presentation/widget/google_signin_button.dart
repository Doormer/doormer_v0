import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:doormer/src/features/auth/presentation/bloc/auth_bloc.dart';

class GoogleSignInButton extends StatefulWidget {
  /// The minimum width for the Google Sign-In button.
  final double minimumWidth;

  /// The text configuration for the button.
  final web.GSIButtonText buttonText;

  const GoogleSignInButton({
    super.key,
    this.minimumWidth = 320 - 50,
    this.buttonText = web.GSIButtonText.continueWith,
  });

  @override
  GoogleSignInButtonState createState() => GoogleSignInButtonState();
}

class GoogleSignInButtonState extends State<GoogleSignInButton> {
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    // Retrieve the GoogleSignIn instance from serviceLocator
    _googleSignIn = serviceLocator<GoogleSignIn>();

    // Listen for sign-in events
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        _handleGoogleSignIn(account);
      }
    });
  }

  void _handleGoogleSignIn(GoogleSignInAccount account) async {
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;

    if (!mounted) return; // Prevent calling context if the widget is disposed

    if (idToken != null) {
      // Dispatch Bloc event with the retrieved ID token
      context.read<AuthBloc>().add(GoogleSignInRequested(idToken));
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
        'GoogleSignInPlatform instance: ${GoogleSignInPlatform.instance.runtimeType}');
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: widget.minimumWidth,
        height: 44,
        child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
            .renderButton(
          configuration: web.GSIButtonConfiguration(
            type: web.GSIButtonType.standard,
            theme: web.GSIButtonTheme.outline,
            size: web.GSIButtonSize.large,
            text: widget.buttonText,
            shape: web.GSIButtonShape.pill,
            logoAlignment: web.GSIButtonLogoAlignment.left,
            minimumWidth: widget.minimumWidth,
          ),
        ),
      ),
    );
  }
}
