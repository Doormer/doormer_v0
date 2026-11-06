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
          // The mockup's `linear-gradient(160deg, …)`.
          transform: _CssAngle(160),
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
                  transform: const _FillBoxAsEllipse(),
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
            // bar's, give that back: the content sits 16 in from every edge,
            // and the bar 14 under the icons.
            padding: EdgeInsets.fromLTRB(16.w, 7.h, 2.w, 14.h),
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

/// Runs a top-to-bottom [LinearGradient] at a CSS angle in [degrees]
/// (0 is up, 90 right). Like CSS, it puts the first colour on one corner
/// and the last on the opposite one.
class _CssAngle extends GradientTransform {
  final double degrees;

  const _CssAngle(this.degrees);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final angle = degrees * math.pi / 180;
    // CSS's gradient line: long enough that lines across it at its two
    // ends pass through the corners.
    final length = (bounds.width * math.sin(angle)).abs() +
        (bounds.height * math.cos(angle)).abs();
    final centre = bounds.center;
    return Matrix4.identity()
      ..translate(centre.dx, centre.dy)
      ..rotateZ(angle - math.pi)
      ..scale(1.0, length / bounds.height)
      ..translate(-centre.dx, -centre.dy);
  }
}

/// Stretches a [RadialGradient] from a circle into the ellipse that fills
/// its box, as CSS's `radial-gradient(closest-side, …)` does. Flutter
/// draws a circle as wide as the box's shorter side.
class _FillBoxAsEllipse extends GradientTransform {
  const _FillBoxAsEllipse();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final centre = bounds.center;
    return Matrix4.identity()
      ..translate(centre.dx, centre.dy)
      ..scale(bounds.width / bounds.shortestSide,
          bounds.height / bounds.shortestSide)
      ..translate(-centre.dx, -centre.dy);
  }
}
