import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/params/share_question_sheet_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shares the student's question with friends: what friends will see, a tick
/// box for each friend, and Send.
class ShareQuestionSheetOrganism extends StatelessWidget {
  /// The widest the sheet's body grows. On a wide screen the tick boxes, the
  /// names and Send stay together on the left, as Add a friend's body does.
  static const double maxBodyWidth = 520;

  final ShareQuestionSheetParams params;

  const ShareQuestionSheetOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(fontSize: 13.sp, color: QuestPalette.body);
    return Container(
      decoration: BoxDecoration(
        color: QuestPalette.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          // A long list of friends scrolls inside the sheet, which never
          // covers the whole screen.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxBodyWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Share with friends',
                            style: TextStyle(
                              fontFamily: kDisplayFont,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: QuestPalette.cream,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('share_close'),
                          onPressed: params.onClose,
                          icon: const Icon(Icons.close),
                          color: QuestPalette.muted,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.photo_outlined,
                            size: 16.w, color: QuestPalette.muted),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Friends will see your photo and the full solution',
                            style: TextStyle(
                                fontSize: 12.sp, color: QuestPalette.body),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    ..._body(bodyStyle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(TextStyle bodyStyle) {
    return switch (params.body) {
      ShareSheetLoadingParams() => [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(
              child: CircularProgressIndicator(color: QuestPalette.violet),
            ),
          ),
        ],
      ShareSheetMessageParams(:final message, :final onRetry) => [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(message, style: bodyStyle),
          ),
          if (onRetry != null)
            AppButtonAtom(label: 'Try again', expand: true, onPressed: onRetry),
        ],
      ShareSheetFriendsParams friends => [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final friend in friends.friends) _FriendTick(friend),
              ],
            ),
          ),
          if (friends.isFull)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                'Up to 10 at a time.',
                style: TextStyle(fontSize: 12.sp, color: QuestPalette.muted),
              ),
            ),
          SizedBox(height: 12.h),
          AppButtonAtom(
            label: 'Send',
            icon: Icons.send_rounded,
            expand: true,
            isLoading: friends.isSending,
            onPressed: friends.onSend,
          ),
        ],
    };
  }
}

/// A friend's tick box, picture and nickname. A friend who already has the
/// question is marked Shared, under their nickname.
class _FriendTick extends StatelessWidget {
  final ShareFriendRowParams friend;

  const _FriendTick(this.friend);

  @override
  Widget build(BuildContext context) {
    final onToggle = friend.onToggle;
    return CheckboxListTile(
      value: friend.isTicked,
      onChanged: onToggle == null ? null : (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: QuestPalette.violet,
      title: Row(
        children: [
          CardPictureAtom(
            name: friend.nickname,
            artUrl: friend.artUrl,
            size: 28.w,
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, color: QuestPalette.cream),
                ),
                if (friend.isShared)
                  Text(
                    'Shared',
                    style:
                        TextStyle(fontSize: 11.sp, color: QuestPalette.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
