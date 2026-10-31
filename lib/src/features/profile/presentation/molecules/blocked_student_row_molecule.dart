import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/blocked_student_row_params.dart';

/// A blocked student: their picture and nickname, and Unblock.
class BlockedStudentRowMolecule extends StatelessWidget {
  final BlockedStudentRowParams params;

  const BlockedStudentRowMolecule({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          CardPictureAtom(
            name: params.nickname,
            artUrl: params.artUrl,
            size: 40.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              params.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, color: QuestPalette.cream),
            ),
          ),
          SizedBox(width: 8.w),
          AppButtonAtom(
            label: 'Unblock',
            variant: AppButtonVariant.outlined,
            isLoading: params.isUnblocking,
            onPressed: params.onUnblock,
          ),
        ],
      ),
    );
  }
}
