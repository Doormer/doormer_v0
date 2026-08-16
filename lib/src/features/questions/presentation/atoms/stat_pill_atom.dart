import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A small stat pill — the XP total, the streak.
///
/// Colour is the meaning: mint for what has been banked, amber for what is at
/// stake. Nothing else on the page may use those two for anything else.
class StatPillAtom extends StatelessWidget {
  final IconData icon;

  /// Marks the icon so something can be aimed at the pill's emblem rather than
  /// at the pill's centre, which drifts as the label's digits grow.
  final Key? iconKey;
  final String label;
  final Color accent;

  const StatPillAtom({
    super.key,
    required this.icon,
    this.iconKey,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, key: iconKey, size: 12.sp, color: accent),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: kDisplayFont,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: accent,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
