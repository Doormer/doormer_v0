import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/friend_request_row_params.dart';

enum _RequestAction { block, report }

/// A request waiting: the sender's picture and nickname, Accept and Decline,
/// and a menu with Block and Report, so a stranger's request can be dealt
/// with without accepting it.
class FriendRequestRowMolecule extends StatelessWidget {
  final FriendRequestRowParams params;

  const FriendRequestRowMolecule({super.key, required this.params});

  void _act(_RequestAction action) => switch (action) {
        _RequestAction.block => params.onBlock(),
        _RequestAction.report => params.onReport(),
      };

  @override
  Widget build(BuildContext context) {
    final isBusy = params.isBusy;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardPictureAtom(
            name: params.nickname,
            artUrl: params.artUrl,
            size: 40.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  params.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, color: QuestPalette.cream),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    AppButtonAtom(
                      label: 'Accept',
                      onPressed: isBusy ? null : params.onAccept,
                    ),
                    AppButtonAtom(
                      label: 'Decline',
                      variant: AppButtonVariant.outlined,
                      onPressed: isBusy ? null : params.onDecline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isBusy)
            Padding(
              padding: EdgeInsets.all(12.w),
              child: SizedBox.square(
                dimension: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<_RequestAction>(
              tooltip: 'Options',
              icon: const Icon(Icons.more_vert, color: QuestPalette.muted),
              onSelected: _act,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: _RequestAction.block, child: Text('Block')),
                PopupMenuItem(
                  value: _RequestAction.report,
                  child: Text('Report'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
