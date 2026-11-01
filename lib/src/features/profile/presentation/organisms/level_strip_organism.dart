import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../params/level_strip_params.dart';

/// The student's own level: its icons and "Level 21", with ⓘ for How levels
/// work straight after it, as Edit follows the nickname, then their active
/// days and what the next level adds.
class LevelStripOrganism extends StatelessWidget {
  final LevelStripParams params;

  const LevelStripOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final level = params.level;
    return SurfaceCardAtom(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 8.w, 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (level.number > 0) ...[
                // "Level 21" says it, so screen readers skip the icons.
                LevelIconsAtom(
                  suns: level.suns,
                  moons: level.moons,
                  stars: level.stars,
                  size: 18.w,
                  semanticLabel: null,
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  params.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.cream,
                  ),
                ),
              ),
              IconButton(
                onPressed: params.onExplain,
                icon: Icon(Icons.info_outline_rounded, size: 18.w),
                color: QuestPalette.muted,
                tooltip: 'How levels work',
              ),
            ],
          ),
          Text(
            params.activeDaysLine,
            style: TextStyle(fontSize: 12.sp, color: QuestPalette.body),
          ),
        ],
      ),
    );
  }
}
