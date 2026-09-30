import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../mapper/collection_presenter.dart';

/// The student's quarks: a quark dot beside "605 quarks".
///
/// Shown wherever a student might be about to spend, so quarks are never
/// earned or spent out of sight.
class QuarkBalanceAtom extends StatelessWidget {
  final int quarkBalance;

  /// Put on the quark dot, so a caller can measure where it sits. The quark
  /// dots of a shatter land there.
  final Key? dotKey;

  const QuarkBalanceAtom({
    super.key,
    required this.quarkBalance,
    this.dotKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: dotKey,
          width: 6.w,
          height: 6.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: QuestPalette.amber,
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            CollectionPresenter.quarkBalanceLabel(quarkBalance),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5.sp, color: QuestPalette.dim),
          ),
        ),
      ],
    );
  }
}
