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

  /// How much the balance glows, from 0 to 1. A glowing balance turns amber
  /// and glows the way a flying quark dot does. Only colours and shadows
  /// change, never the size, so quark dots aimed at the balance still land
  /// on it.
  final double glow;

  const QuarkBalanceAtom({
    super.key,
    required this.quarkBalance,
    this.dotKey,
    this.glow = 0,
  });

  @override
  Widget build(BuildContext context) {
    final glowColour = QuestPalette.amber.withValues(alpha: 0.7 * glow);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: dotKey,
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: QuestPalette.amber,
            boxShadow:
                glow > 0 ? [BoxShadow(color: glowColour, blurRadius: 8)] : null,
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            CollectionPresenter.quarkBalanceLabel(quarkBalance),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: Color.lerp(QuestPalette.dim, QuestPalette.amber, glow),
              shadows:
                  glow > 0 ? [Shadow(color: glowColour, blurRadius: 8)] : null,
            ),
          ),
        ),
      ],
    );
  }
}
