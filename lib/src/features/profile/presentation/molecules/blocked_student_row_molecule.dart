import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/blocked_student_row_params.dart';

/// A blocked student: their picture and nickname, and Unblock.
class BlockedStudentRowMolecule extends StatelessWidget {
  final BlockedStudentRowParams params;

  /// Drawn as a tile of its own, with Unblock in it.
  final bool isTile;

  const BlockedStudentRowMolecule({
    super.key,
    required this.params,
    this.isTile = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
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
    );

    if (isTile) return TileAtom(child: content);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: content,
    );
  }
}
