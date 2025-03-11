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

  const GoogleSignInButton({
    super.key,
    this.minimumWidth = 320 - 50,
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
    return Column(
      children: [
        // Render Google Sign-In button with custom minimum width from the widget property.
        SizedBox(
          child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
              .renderButton(
            configuration: web.GSIButtonConfiguration(
              type: web.GSIButtonType.standard,
              theme: web.GSIButtonTheme.filledBlue,
              size: web.GSIButtonSize.large,
              text: web.GSIButtonText.continueWith,
              shape: web.GSIButtonShape.rectangular,
              logoAlignment: web.GSIButtonLogoAlignment.left,
              minimumWidth: widget.minimumWidth,
            ),
          ),
        ),
      ],
    );
  }
}
