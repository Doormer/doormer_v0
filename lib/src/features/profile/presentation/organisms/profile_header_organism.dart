import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/profile_header_params.dart';

/// The student's picture, nickname and friend code, with Edit.
class ProfileHeaderOrganism extends StatelessWidget {
  final ProfileHeaderParams params;

  const ProfileHeaderOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CardPictureAtom(
          name: params.nickname,
          artUrl: params.artUrl,
          size: 64.w,
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
                  fontFamily: kDisplayFont,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: QuestPalette.cream,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Friend code',
                style: TextStyle(fontSize: 11.sp, color: QuestPalette.muted),
              ),
              SelectableText(
                params.friendCode,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: QuestPalette.body,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: params.onEdit, child: const Text('Edit')),
      ],
    );
  }
}
