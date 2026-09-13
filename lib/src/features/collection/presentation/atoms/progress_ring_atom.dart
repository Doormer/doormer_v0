import 'dart:math' as math;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Deck progress as a ring with the held count inside.
///
/// A ring rather than a bar because it stays legible at 19px and reads the same
/// in the rail and on a phone. A complete deck rings [QuestPalette.mint] — the
/// same colour a completed card carries, so completion looks identical wherever
/// it appears.
class ProgressRingAtom extends StatelessWidget {
  final int held;
  final int total;
  final double size;

  const ProgressRingAtom({
    super.key,
    required this.held,
    required this.total,
    this.size = 19,
  });

  bool get isComplete => total > 0 && held >= total;

  /// Guarded against a zero-card deck, which would otherwise divide by zero.
  double get fraction => total <= 0 ? 0.0 : math.min(held / total, 1.0);

  Color get ringColour => isComplete ? QuestPalette.mint : QuestPalette.amber;

  @override
  Widget build(BuildContext context) {
    final side = size.w;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 2.w,
              backgroundColor: QuestPalette.cream.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(ringColour),
            ),
          ),
          Text(
            '$held',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: QuestPalette.body,
            ),
          ),
        ],
      ),
    );
  }
}
