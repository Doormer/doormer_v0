import 'package:doormer/src/core/agreement_texts/agreement_text.dart';
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AgreementTextWidget extends StatelessWidget {
  const AgreementTextWidget({Key? key}) : super(key: key);

  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true, // Allows the bottom sheet to take more space
      context: context,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.9;
        return Container(
          color: AppColors.background, // Use your app's background color here
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
          color: AppColors.background, // Use your app's background color here
          padding: const EdgeInsets.all(16.0),
          height: height,
          child: AgreementText.privacyPolicy,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: "By continuing, you agree to our\n",
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
            text: "Terms & Conditions",
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.black,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showTermsSheet(context);
              },
          ),
          const TextSpan(
            text: " and ",
            style: TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: "Privacy Policy",
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.black,
            ),
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
