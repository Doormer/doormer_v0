import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A study tip to read while a photo is being solved.
class StudyTipMolecule extends StatelessWidget {
  final String tip;

  const StudyTipMolecule({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return SurfaceCardAtom(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 20.sp,
            color: QuestPalette.amber,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tip', style: tt.titleSmall?.copyWith(fontSize: 14.sp)),
                SizedBox(height: 4.h),
                Text(tip, style: tt.bodyMedium?.copyWith(fontSize: 14.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
