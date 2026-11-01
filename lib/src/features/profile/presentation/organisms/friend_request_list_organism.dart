import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_grid_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/friend_request_row_molecule.dart';
import '../params/friend_request_row_params.dart';

/// The requests waiting for an answer, newest first. Profile shows it only
/// while any are waiting. With more than one column, the rows are tiles,
/// [columns] to a line, so each request's menu stays beside the sender's
/// name.
class FriendRequestListOrganism extends StatelessWidget {
  final List<FriendRequestRowParams> requests;

  /// How many requests sit side by side. With 1, each is a row of its own.
  final int columns;

  const FriendRequestListOrganism({
    super.key,
    required this.requests,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final isTiled = columns > 1;
    final rows = [
      for (final request in requests)
        FriendRequestRowMolecule(params: request, isTile: isTiled),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Requests',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: QuestPalette.dim,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        if (isTiled)
          TileGridAtom(columns: columns, children: rows)
        else
          ...rows,
      ],
    );
  }
}
