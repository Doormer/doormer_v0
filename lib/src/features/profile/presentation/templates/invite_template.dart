import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What an invite link shows a student who isn't signed in. It doesn't name
/// the inviter, so a forwarded link gives nothing away.
class InviteTemplate extends StatelessWidget {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
    );
  }
}
