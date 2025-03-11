import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
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
      height: 40, // Set the button height
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                color: AppColors.surface,
              )
            : Text(buttonText, style: AppTextStyles.buttonText),
      ),
    );
  }
}
