import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/friend_row_params.dart';

enum _FriendAction { remove, block, report }

/// A friend: their picture, nickname and level, which open their collection,
/// and a menu with Remove, Block and Report. The level's icons follow the
/// nickname, which is cut short before they are pushed off.
class FriendRowMolecule extends StatelessWidget {
  final FriendRowParams params;

  /// Drawn as a tile of its own, which opens the collection wherever it is
  /// tapped, apart from the menu.
  final bool isTile;

  const FriendRowMolecule({
    super.key,
    required this.params,
    this.isTile = false,
  });

  void _act(_FriendAction action) => switch (action) {
        _FriendAction.remove => params.onRemove(),
        _FriendAction.block => params.onBlock(),
        _FriendAction.report => params.onReport(),
      };

  @override
  Widget build(BuildContext context) {
    final onOpen = params.isBusy ? null : params.onOpen;
    final level = params.level;
    final content = Row(
      children: [
        CardPictureAtom(
          name: params.nickname,
          artUrl: params.artUrl,
          size: 40.w,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  params.nickname,
                  semanticsLabel: params.semanticsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, color: QuestPalette.cream),
                ),
              ),
              if (level != null) ...[
                SizedBox(width: 6.w),
                // The nickname's label says the level, so screen readers
                // skip the icons.
                LevelIconsAtom(
                  suns: level.suns,
                  moons: level.moons,
                  stars: level.stars,
                  size: 16.w,
                  semanticLabel: null,
                ),
              ],
            ],
          ),
        ),
        if (params.isBusy)
          Padding(
            padding: EdgeInsets.all(12.w),
            child: SizedBox.square(
              dimension: 20.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          PopupMenuButton<_FriendAction>(
            tooltip: 'Options',
            icon: const Icon(Icons.more_vert, color: QuestPalette.muted),
            onSelected: _act,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _FriendAction.remove,
                child: Text('Remove'),
              ),
              PopupMenuItem(
                value: _FriendAction.block,
                child: Text('Block'),
              ),
              PopupMenuItem(
                value: _FriendAction.report,
                child: Text('Report'),
              ),
            ],
          ),
      ],
    );

    if (isTile) return TileAtom(onTap: onOpen, child: content);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          child: content,
        ),
      ),
    );
  }
}
