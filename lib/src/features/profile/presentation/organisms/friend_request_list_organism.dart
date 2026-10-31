import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/friend_request_row_molecule.dart';
import '../params/friend_request_row_params.dart';

/// The requests waiting for an answer, newest first. Profile shows it only
/// while any are waiting.
class FriendRequestListOrganism extends StatelessWidget {
  final List<FriendRequestRowParams> requests;

  const FriendRequestListOrganism({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
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
        for (final request in requests)
          FriendRequestRowMolecule(params: request),
      ],
    );
  }
}
