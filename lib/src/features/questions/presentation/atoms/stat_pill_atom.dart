import 'dart:math' as math;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
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

  /// Bobs the emblem a few times on arrival. Reserved for a stat that is a
  /// living thing rather than a running total — a streak can be lost, and the
  /// flicker is what says so.
  final bool alive;

  const StatPillAtom({
    super.key,
    required this.icon,
    this.iconKey,
    required this.label,
    required this.accent,
    this.alive = false,
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
          _emblem(),
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

  Widget _emblem() {
    final icon = Icon(this.icon, key: iconKey, size: 12.sp, color: accent);
    if (!alive) return icon;
    return IdleBeatAtom(
      period: const Duration(milliseconds: 1500),
      beats: 4,
      child: icon,
      builder: (context, phase, child) {
        // Up and over, then back: a flame leans as it rises.
        final rise = (1 - math.cos(phase * 2 * math.pi)) / 2;
        final lean = math.sin(phase * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, -3 * rise),
          child:
              Transform.rotate(angle: lean * 6 * math.pi / 180, child: child),
        );
      },
    );
  }
}
