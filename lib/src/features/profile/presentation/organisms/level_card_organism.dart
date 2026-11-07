import 'package:doormer/src/core/theme/css_gradients.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icons_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../atoms/gold_panel_atom.dart';
import '../molecules/level_progress_bar_molecule.dart';
import '../params/level_card_params.dart';

/// The student's own level, at the top of Profile: its golden icons and
/// "Level 21", with ⓘ for How levels work at the right, then a bar of how
/// far through this level they are, their active days, and the days to the
/// next level's icon.
class LevelCardOrganism extends StatelessWidget {
  final LevelCardParams params;

  /// Whether it draws its own gold panel. Off when it shares one, as
  /// beside the header on a wide Profile.
  final bool framed;

  const LevelCardOrganism({
    super.key,
    required this.params,
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    // Its own node for screen readers, wherever Profile places it. Beside
    // the header on a wide screen, it would otherwise be heard as part of it.
    final level = _level();
    return Semantics(
      container: true,
      child: framed ? GoldPanelAtom(child: level) : level,
    );
  }

  /// The glow, the icons and title with ⓘ, the bar and the line under it.
  Widget _level() {
    final level = params.level;
    final lineStyle = TextStyle(
      fontFamily: kBodyFont,
      fontSize: 12.5.sp,
      color: QuestPalette.body,
    );
    return Stack(
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
          // top row is 7 taller than the icons above and below them, and the
          // icon sits 14 in from the button's right. These paddings, and the
          // bar's, give that back: the content sits 16 in from the top and
          // sides and 14 from the bottom, as in the mockup, and the bar 14
          // under the icons.
          padding: EdgeInsets.fromLTRB(16.w, 9.h, 2.w, 14.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    // The icons, with no "Level 21" beside them: the days to
                    // the next star under the bar hint at what they mean,
                    // and screen readers hear it. A long row shrinks to
                    // leave ⓘ whole.
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: level.number > 0
                            ? LevelIconsAtom(
                                suns: level.suns,
                                moons: level.moons,
                                stars: level.stars,
                                size: 34.w,
                                semanticLabel: params.levelLabel,
                              )
                            // Level 0: a faded star where the first one will
                            // be.
                            : Semantics(
                                container: true,
                                label: params.levelLabel,
                                child: Opacity(
                                  opacity: 0.35,
                                  child: LevelIconAtom(
                                    icon: LevelIcon.star,
                                    size: 34.w,
                                  ),
                                ),
                              ),
                      ),
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
                padding: EdgeInsets.only(top: 7.h, right: 14.w),
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
    );
  }
}
