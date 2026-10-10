import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Why Doormer shows ads, written for students and the parents helping them.
///
/// Opened from the "Why ads?" link at the top of the solving view, away from
/// the ad. It never asks anyone to tap or look at ads: Google doesn't allow
/// wording that could lead people to click them.
class WhyAdsSheetOrganism extends StatelessWidget {
  final VoidCallback onClose;

  const WhyAdsSheetOrganism({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final paragraphStyle = tt.bodyMedium?.copyWith(fontSize: 14.sp);

    return SafeArea(
      top: false,
      // Scrolls when large text or a short screen leaves too little room.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why we show ads',
              style: tt.titleMedium?.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'Solving a question takes a powerful AI, and every solve costs '
              'us money. An ad shown while you wait helps cover that cost, so '
              'we can keep Doormer free for students.',
              style: paragraphStyle,
            ),
            SizedBox(height: 12.h),
            Text(
              "We ask Google to handle every ad on Doormer as if it's shown "
              'to a child. That turns off ads based on browsing history, and '
              'ads that follow you from other sites.',
              style: paragraphStyle,
            ),
            SizedBox(height: 12.h),
            Text(
              'Ads only appear while a question is being solved, and they '
              'never hold up the answer.',
              style: paragraphStyle,
            ),
            SizedBox(height: 20.h),
            AppButtonAtom(
              label: 'Got it',
              variant: AppButtonVariant.filled,
              expand: true,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
