import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the solver is doing, and why a solve can take minutes.
class SolvingExplanationMolecule extends StatelessWidget {
  /// Opens the explanation of why Doormer shows ads. Null when ads are off,
  /// which also hides the "Why ads?" link.
  final VoidCallback? onWhyAds;

  const SolvingExplanationMolecule({super.key, this.onWhyAds});

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final onWhyAds = this.onWhyAds;
    final iconSize = 20.sp;
    final iconGap = 12.w;

    return SurfaceCardAtom(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: iconSize,
                color: QuestPalette.amber,
              ),
              SizedBox(width: iconGap),
              Expanded(
                child: Text(
                  "What's happening",
                  style: tt.titleSmall?.copyWith(fontSize: 14.sp),
                ),
              ),
              if (onWhyAds != null)
                TextButton(
                  onPressed: onWhyAds,
                  // Compact, so the card stays short enough for the ad below
                  // it to clear the navigation bar on a phone.
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    minimumSize: Size(0, 32.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Why ads?', style: TextStyle(fontSize: 13.sp)),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: iconSize + iconGap),
            child: Text(
              'A powerful AI is reading your photo and working through '
              'the question step by step. Harder questions take longer.',
              style: tt.bodyMedium?.copyWith(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
