import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotFoundPage extends StatelessWidget {
  final VoidCallback onGoHome;

  const NotFoundPage({super.key, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 56.r,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Page not found',
                  style: context.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  "This page doesn't exist or has moved.",
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                AppButtonAtom(label: 'Go home', onPressed: onGoHome),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
