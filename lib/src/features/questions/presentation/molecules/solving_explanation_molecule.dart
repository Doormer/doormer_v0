import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the solver is doing, and why a solve can take minutes.
class SolvingExplanationMolecule extends StatelessWidget {
  const SolvingExplanationMolecule({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return SurfaceCardAtom(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 20.sp,
            color: QuestPalette.amber,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's happening",
                  style: tt.titleSmall?.copyWith(fontSize: 14.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  'A powerful AI is reading your photo and working through '
                  'the question step by step. Harder questions take longer.',
                  style: tt.bodyMedium?.copyWith(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
