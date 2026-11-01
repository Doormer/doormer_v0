import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/profile_header_params.dart';

/// The student's picture, nickname and friend code, with Edit straight after
/// the nickname. A long nickname is cut short before Edit is pushed off.
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
              Row(
                children: [
                  Flexible(
                    child: Text(
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
                  ),
                  SizedBox(width: 6.w),
                  TextButton.icon(
                    onPressed: params.onEdit,
                    icon: Icon(Icons.edit_outlined, size: 14.w),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size(0, 32.h),
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
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
      ],
    );
  }
}
