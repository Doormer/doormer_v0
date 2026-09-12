import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';

class SignUpButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String buttonText;

  const SignUpButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.buttonText = 'Sign Up',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator(
                color: context.colorScheme.onPrimary,
              )
            : Text(buttonText),
      ),
    );
  }
}
