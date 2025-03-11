import 'package:doormer/src/core/config/app_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class RegistrationCompletePage extends StatelessWidget {
  const RegistrationCompletePage({Key? key}) : super(key: key);

  Future<void> _launchSurvey() async {
    final Uri url = Uri.parse(AppConfig.surveyURL);
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 18, color: Colors.black),
              children: [
                const TextSpan(
                  text: "Registration complete.\n\n",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  text: "Please access the beta version through ",
                ),
                const TextSpan(
                  text: "email",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  text: " or ",
                ),
                const TextSpan(
                  text: "www.doormer.com",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: ".\n\n\n\n",
                ),
                const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  text:
                      "We’d appreciate it if you could take a moment to complete a short survey (1–2 minutes) to help us improve your experience.\n\n ",
                ),
                TextSpan(
                  text: "Take our survey",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _launchSurvey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
