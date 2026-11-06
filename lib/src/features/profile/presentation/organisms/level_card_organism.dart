import 'package:doormer/src/core/theme/css_gradients.dart';
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
          // The mockup's `linear-gradient(160deg, …)`.
          transform: CssAngle(160),
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
                  // The mockup's `radial-gradient(closest-side, …)`: an
                  // ellipse filling the 260 by 160 box.
                  transform: const FillBoxAsEllipse(),
                  colors: [
                    QuestPalette.levelHalo.withValues(alpha: 0.22),
                    QuestPalette.levelHalo.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            // The ⓘ button is 48 square with its 20 icon in the middle, so the
            // top row is 9 taller than the icons above and below them, and the
            // icon sits 14 in from the button's right. These paddings, and the
            // bar's, give that back: the content sits 16 in from the top and
            // sides and 14 from the bottom, as in the mockup, and the bar 14
            // under the icons.
            padding: EdgeInsets.fromLTRB(16.w, 7.h, 2.w, 14.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      // The icons give way first: a long row of them shrinks
                      // to leave the title whole. Only when the title alone
                      // can't fit, in a narrow card with big text, does it
                      // shrink too, rather than run under ⓘ.
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final hasIcons = level.number > 0;
                          final gap = hasIcons ? 12.w : 0.0;
                          return Row(
                            children: [
                              if (hasIcons) ...[
                                // "Level 21" says it, so screen readers skip
                                // the icons.
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
                                SizedBox(width: gap),
                              ],
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: box.maxWidth > gap
                                      ? box.maxWidth - gap
                                      : 0,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    params.title,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: kDisplayFont,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w700,
                                      color: QuestPalette.levelCream,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                        width: 48.w,
                        height: 48.w,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 5.h, right: 14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LevelProgressBarMolecule(
                        fill: params.barFill,
                        nextLevelIcon: params.nextLevelIcon,
                      ),
                      SizedBox(height: 9.h),
                      // Side by side when they fit. With big text, the days
                      // to go drop under the active days.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12.w,
                        children: [
                          Text(params.activeDaysLabel, style: lineStyle),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: params.daysToGoLabel,
                                  style: const TextStyle(
                                    color: QuestPalette.levelPaleGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' ${params.toNextIconLabel}'),
                              ],
                            ),
                            style: lineStyle,
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
