import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The face-down card: a lattice over a deep violet field.
///
/// Universal across decks. A deck may override it later, which is why the art
/// is drawn here rather than baked into the reveal.
class CardBackAtom extends StatelessWidget {
  final double? width;

  const CardBackAtom({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final w = width ?? 118.w;
    return Container(
      width: w,
      height: w * 3 / 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: QuestPalette.amber.withValues(alpha: 0.20)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241D4C), Color(0xFF141030), Color(0xFF0A0818)],
        ),
      ),
      child: Center(
        child: Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: QuestPalette.amber.withValues(alpha: 0.5),
              width: 1.5.w,
            ),
          ),
          child: Center(
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: QuestPalette.amber.withValues(alpha: 0.78),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
