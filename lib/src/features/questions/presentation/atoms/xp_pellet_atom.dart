import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The XP a step just banked, in flight from the card to the counter.
///
/// It carries [amount] — what was actually banked — not whatever the sticker
/// currently reads. The sticker shows the value of the step now on screen,
/// which is the *next* reward; reading it sends a pellet saying "+15" while
/// the counter climbs by 10.
class XpPelletAtom extends StatelessWidget {
  final int amount;

  const XpPelletAtom({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: QuestPalette.mint,
        borderRadius: BorderRadius.circular(99.r),
        boxShadow: [
          BoxShadow(
            color: QuestPalette.mint.withValues(alpha: 0.9),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -7,
          ),
        ],
      ),
      child: Text(
        '+$amount XP',
        style: TextStyle(
          fontFamily: kDisplayFont,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: QuestPalette.onMint,
          height: 1.2,
        ),
      ),
    );
  }
}
