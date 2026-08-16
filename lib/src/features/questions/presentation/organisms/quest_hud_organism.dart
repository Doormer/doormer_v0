import 'package:doormer/src/features/questions/presentation/atoms/stat_pill_atom.dart';
import 'package:doormer/src/features/questions/presentation/params/quest_hud_params.dart';
import 'package:flutter/widgets.dart';

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The page's standing bar: where this question sits, what it is called, and
/// what the student is carrying.
///
/// The pills are absent, not zeroed, until the standing loads. A "0 XP" that
/// silently becomes "120 XP" a frame later reads as losing something.
class QuestHudOrganism extends StatelessWidget {
  final QuestHudParams params;

  const QuestHudOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('quest_hud'),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  params.topic.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.sp,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.muted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  params.questionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.cream,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          if (params.xpLabel.isNotEmpty) ...[
            SizedBox(width: 8.w),
            StatPillAtom(
              key: const Key('hud_xp'),
              icon: Icons.bolt_rounded,
              label: params.xpLabel,
              accent: QuestPalette.mint,
            ),
          ],
          if (params.streakLabel.isNotEmpty) ...[
            SizedBox(width: 6.w),
            StatPillAtom(
              key: const Key('hud_streak'),
              icon: Icons.local_fire_department_rounded,
              label: params.streakLabel,
              accent: QuestPalette.amber,
            ),
          ],
        ],
      ),
    );
  }
}
