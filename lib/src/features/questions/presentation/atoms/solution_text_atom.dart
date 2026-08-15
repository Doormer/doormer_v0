import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One prose paragraph from a solution body.
class SolutionTextAtom extends StatelessWidget {
  final String value;

  const SolutionTextAtom({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Text(
        value,
        style: context.textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
          height: 1.5,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }
}
