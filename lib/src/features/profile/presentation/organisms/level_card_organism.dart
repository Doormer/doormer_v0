import 'dart:math' as math;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/level_progress_bar_molecule.dart';
import '../params/level_card_params.dart';

/// The student's own level, at the top of Profile: its golden icons and
/// "Level 21", with ⓘ for How levels work at the right, then a bar of how
/// far through this level they are, their active days, and the days to the
/// next level's icon.
class LevelCardOrganism extends StatelessWidget {
  final LevelCardParams params;

  const LevelCardOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final level = params.level;
    final lineStyle = TextStyle(
      fontFamily: kBodyFont,
      fontSize: 12.5.sp,
      color: QuestPalette.body,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: QuestPalette.levelGold.withValues(alpha: 0.22),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // The mockup's 160°: downward, leaning to the right.
          transform: GradientRotation(-20 * math.pi / 180),
          colors: [
            QuestPalette.levelCardTop,
            QuestPalette.levelCardMiddle,
            QuestPalette.levelCardBottom,
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          // A soft gold glow behind the icons.
          Positioned(
            left: -30.w,
            top: -60.h,
            width: 260.w,
            height: 160.h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    QuestPalette.levelHalo.withValues(alpha: 0.22),
                    QuestPalette.levelHalo.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            // The ⓘ button is 40 tall, 10 more than the icons, and its icon
            // sits 10 in from its right: the padding gives that back, so the
            // card's content sits 16 in from every edge.
            padding: EdgeInsets.fromLTRB(16.w, 11.h, 6.w, 14.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (level.number > 0) ...[
                            // "Level 21" says it, so screen readers skip the
                            // icons. A long row of them shrinks to leave the
                            // title whole.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: LevelIconsAtom(
                                  suns: level.suns,
                                  moons: level.moons,
                                  stars: level.stars,
                                  size: 30.w,
                                  semanticLabel: null,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Text(
                            params.title,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: kDisplayFont,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: QuestPalette.levelCream,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: params.onExplain,
                      icon: Icon(Icons.info_outline_rounded, size: 20.w),
                      color: QuestPalette.muted,
                      tooltip: 'How levels work',
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.standard,
                      constraints: BoxConstraints.tightFor(
                        width: 40.w,
                        height: 40.w,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 9.h, right: 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LevelProgressBarMolecule(
                        fill: params.barFill,
                        nextLevelIcon: params.nextLevelIcon,
                      ),
                      SizedBox(height: 9.h),
                      Row(
                        children: [
                          Text(params.activeDaysLabel, style: lineStyle),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: params.daysToGoLabel,
                                    style: const TextStyle(
                                      color: QuestPalette.levelPaleGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' ${params.nextLevelLabel}'),
                                ],
                              ),
                              textAlign: TextAlign.end,
                              style: lineStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
