import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_grid_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/friend_row_molecule.dart';
import '../params/friend_row_params.dart';

/// The student's friends, by nickname. Each row opens that friend's
/// collection. With more than one column, the rows are tiles, [columns] to a
/// line, so each friend's menu stays beside their name.
class FriendListOrganism extends StatelessWidget {
  final List<FriendRowParams> friends;

  /// How many friends sit side by side. With 1, each is a row of its own.
  final int columns;

  const FriendListOrganism({
    super.key,
    required this.friends,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final friend in friends) FriendRowMolecule(params: friend)
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Friends',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: QuestPalette.dim,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        if (friends.isEmpty)
          Text(
            'No friends yet. Add one with their friend code.',
            style: TextStyle(fontSize: 13.sp, color: QuestPalette.muted),
          )
        else if (columns == 1)
          ...rows
        else
          TileGridAtom(columns: columns, children: rows),
      ],
    );
  }
}
