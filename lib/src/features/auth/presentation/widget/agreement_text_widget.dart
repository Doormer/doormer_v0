import 'package:doormer/src/core/agreement_texts/agreement_text.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AgreementTextWidget extends StatelessWidget {
  const AgreementTextWidget({super.key});

  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.9;
        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(16.0),
          height: height,
          child: AgreementText.termsAndConditions,
        );
      },
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.9;
        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(16.0),
          height: height,
          child: AgreementText.privacyPolicy,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final baseStyle = textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface);
    final linkStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary,
    );

    return RichText(
      text: TextSpan(
        text: "By continuing, you agree to our\n",
        style: baseStyle,
        children: [
          TextSpan(
            text: "Terms & Conditions",
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showTermsSheet(context);
              },
          ),
          TextSpan(
            text: " and ",
            style: baseStyle,
          ),
          TextSpan(
            text: "Privacy Policy",
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showPrivacySheet(context);
              },
          ),
        ],
      ),
    );
  }
}
