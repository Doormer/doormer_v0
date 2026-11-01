import 'package:doormer/src/core/config/app_config.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where a signed-in student lands after log-in or registration: a welcome,
/// the way into Solve, and the beta survey.
class RegistrationCompletePage extends StatelessWidget {
  /// Opens the survey. Defaults to the browser; tests pass a fake.
  final Future<bool> Function(Uri url) openSurvey;

  const RegistrationCompletePage({super.key, this.openSurvey = launchUrl});

  Future<void> _openSurvey() async {
    final url = Uri.parse(AppConfig.surveyURL);
    if (!await openSurvey(url)) {
      AppLogger.warn('Could not open the survey at $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You're in!",
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your next quest starts with a photo.',
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: 24.h),
                AppButtonAtom(
                  label: 'Solve a question',
                  icon: Icons.camera_alt,
                  variant: AppButtonVariant.accent,
                  onPressed: () => context.go('/questions/photo'),
                ),
                SizedBox(height: 40.h),
                Text(
                  'Got 2 minutes? Help us make Doormer better.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: _openSurvey,
                  child: const Text('Take the survey'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
