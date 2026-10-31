import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/friend_row_molecule.dart';
import '../params/friend_row_params.dart';

/// The student's friends, by nickname. Each row opens that friend's
/// collection.
class FriendListOrganism extends StatelessWidget {
  final List<FriendRowParams> friends;

  const FriendListOrganism({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
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
        else
          for (final friend in friends) FriendRowMolecule(params: friend),
      ],
    );
  }
}
