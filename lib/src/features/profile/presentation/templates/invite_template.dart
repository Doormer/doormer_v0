import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/doormer_logo_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/rise_in_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What an invite link shows a student who isn't signed in: the Doormer
/// logo, who invited them and what Doormer is, then Sign up and Log in. It
/// doesn't name the inviter, so a forwarded link gives nothing away.
class InviteTemplate extends StatelessWidget {
  /// The widest the column grows, as on the login page.
  static const double maxColumnWidth = 400;

  final VoidCallback onSignUp;
  final VoidCallback onLogIn;

  const InviteTemplate({
    super.key,
    required this.onSignUp,
    required this.onLogIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxColumnWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: RiseInAtom(
                      order: 0,
                      // The heading names Doormer, so screen readers skip
                      // the logo.
                      child: DoormerLogoAtom(
                        size: 88.w,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Semantics(
                    header: true,
                    child: Text(
                      'A friend invited you to Doormer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: QuestPalette.cream,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Snap a homework question and Doormer turns it into a '
                    'step-by-step quest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 14.sp,
                      color: QuestPalette.body,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  AppButtonAtom(
                    label: 'Sign up',
                    expand: true,
                    onPressed: onSignUp,
                  ),
                  SizedBox(height: 12.h),
                  AppButtonAtom(
                    label: 'Log in',
                    variant: AppButtonVariant.outlined,
                    expand: true,
                    onPressed: onLogIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
