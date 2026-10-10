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
              'Every solve runs on a powerful AI that costs us money. Ads '
              'shown while you wait help keep Doormer free for students. We '
              'ask Google not to base them on your browsing history.',
              style: tt.bodyMedium?.copyWith(fontSize: 14.sp),
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
