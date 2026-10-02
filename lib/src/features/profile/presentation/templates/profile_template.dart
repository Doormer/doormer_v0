import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileTemplate extends StatelessWidget {
  final bool isSigningOut;
  final VoidCallback onSignOut;
  final NavigationBarParams navigationBarParams;

  const ProfileTemplate({
    super.key,
    required this.isSigningOut,
    required this.onSignOut,
    required this.navigationBarParams,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          child: NavigationBarOrganism(params: navigationBarParams),
        ),
      ),
    );
  }
}
