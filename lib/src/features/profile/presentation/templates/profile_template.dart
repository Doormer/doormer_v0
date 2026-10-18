import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileTemplate extends StatelessWidget {
  final bool isSigningOut;
  final VoidCallback onSignOut;

  const ProfileTemplate({
    super.key,
    required this.isSigningOut,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Profile', style: context.textTheme.headlineMedium),
              SizedBox(height: 8.h),
              Text(
                'More profile options are coming soon.',
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              AppButtonAtom(
                label: 'Sign out',
                variant: AppButtonVariant.outlined,
                isLoading: isSigningOut,
                onPressed: isSigningOut ? null : onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
