import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The mint XP tag pinned to a card's corner.
///
/// Tilted so it reads as something stuck on afterwards — a reward attached to
/// the work, not a field printed on the card.
class XpStickerAtom extends StatelessWidget {
  final String label;

  const XpStickerAtom({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 3 * 3.1415926535 / 180,
      child: Container(
        key: const Key('step_xp_sticker'),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: QuestPalette.mint,
          borderRadius: BorderRadius.circular(7.r),
          boxShadow: [
            BoxShadow(
              color: QuestPalette.mint.withValues(alpha: 0.35),
              blurRadius: 14,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kDisplayFont,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: QuestPalette.onMint,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
