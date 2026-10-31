import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/found_student_params.dart';

/// The owner of a code just found: their picture and nickname, so the
/// student can check it's the right person, how the two are connected, and
/// what can be done next.
class FoundStudentOrganism extends StatelessWidget {
  final FoundStudentParams params;

  const FoundStudentOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final status = params.status;
    final actionLabel = params.actionLabel;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: QuestPalette.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          CardPictureAtom(
            name: params.nickname,
            artUrl: params.artUrl,
            size: 56.w,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  params.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.cream,
                  ),
                ),
                if (status != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    status,
                    style: TextStyle(fontSize: 12.sp, color: QuestPalette.dim),
                  ),
                ],
                if (actionLabel != null) ...[
                  SizedBox(height: 10.h),
                  AppButtonAtom(
                    label: actionLabel,
                    isLoading: params.isActing,
                    onPressed: params.onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
