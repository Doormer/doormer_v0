import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tells students, and parents helping them, that an ad may show while a
/// photo is being solved, with a link to why.
///
/// It belongs on screens without an ad. Google doesn't allow wording near
/// its ads that could lead people to click them.
class AdsNoticeMolecule extends StatelessWidget {
  final VoidCallback onWhyAds;

  const AdsNoticeMolecule({super.key, required this.onWhyAds});

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doormer is free to use. You may see an ad while your photo is '
          'being solved.',
          style: tt.bodySmall?.copyWith(
            fontSize: 12.sp,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onWhyAds,
          // No side padding, so the link lines up with the sentence above.
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 36.h),
          ),
          child: Text('Why ads?', style: TextStyle(fontSize: 12.sp)),
        ),
      ],
    );
  }
}
