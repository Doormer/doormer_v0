import 'package:doormer/src/core/agreement_texts/agreement_text.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AgreementTextWidget extends StatelessWidget {
  const AgreementTextWidget({super.key});

  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (_) => const _AgreementSheet(
        title: 'Terms of Service',
        child: AgreementText.termsAndConditions,
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (_) => const _AgreementSheet(
        title: 'Privacy Policy',
        child: AgreementText.privacyPolicy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final baseStyle =
        textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface);
    final linkStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary,
    );

    return RichText(
      textAlign: TextAlign.center,
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

class _AgreementSheet extends StatelessWidget {
  const _AgreementSheet({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      height: height,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
