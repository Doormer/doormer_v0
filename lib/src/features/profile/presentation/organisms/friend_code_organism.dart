import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/friend_code_params.dart';

/// The student's own friend code, with Copy, Copy invite link and Reset
/// code.
class FriendCodeOrganism extends StatelessWidget {
  final FriendCodeParams params;

  const FriendCodeOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your friend code',
          style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                params.friendCode,
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: QuestPalette.cream,
                ),
              ),
            ),
            if (params.isResetting)
              SizedBox.square(
                dimension: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            AppButtonAtom(
              label: 'Copy',
              icon: Icons.copy,
              variant: AppButtonVariant.outlined,
              onPressed: params.isResetting ? null : params.onCopyCode,
            ),
            AppButtonAtom(
              label: 'Copy invite link',
              icon: Icons.link,
              variant: AppButtonVariant.outlined,
              onPressed: params.isResetting ? null : params.onCopyInviteLink,
            ),
          ],
        ),
        TextButton(
          onPressed: params.isResetting ? null : params.onResetCode,
          child: const Text('Reset code'),
        ),
      ],
    );
  }
}
