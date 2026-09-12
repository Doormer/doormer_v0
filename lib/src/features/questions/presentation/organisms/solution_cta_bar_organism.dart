import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quest_cta_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quest_ghost_button_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/swipe_hint_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_cta_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The dock at the foot of the reader: back, the one big button, and the swipe
/// hint floating above them.
///
/// Paints no fill of its own, just a fade above it. Nothing scrolls behind the
/// dock -- it is a sibling below the scroll view, not an overlay on top of one
/// -- so a fill buys no occlusion, and an opaque one is actively wrong on a
/// wide window: it is clipped to the content column, so it ends in a hard
/// vertical edge with the app backdrop still showing either side of it.
///
/// If you reintroduce a fill here, check it at 1440px wide, not just on a
/// phone. On a phone the column is the window and the seam cannot appear.
class SolutionCtaBarOrganism extends StatelessWidget {
  final SolutionCtaBarParams params;

  const SolutionCtaBarOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IgnorePointer(
          child: Container(
            height: 26.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  QuestPalette.glowBottom.withValues(alpha: 0),
                  QuestPalette.glowBottom,
                ],
              ),
            ),
          ),
        ),
        Stack(
          alignment: Alignment.topCenter,
          // The hint reaches up out of the dock; clipping erases it.
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(13.w, 11.h, 13.w, 13.h),
              child: Row(
                children: [
                  QuestGhostButtonAtom(
                    label: 'Back',
                    icon: Icons.chevron_left_rounded,
                    enabled: params.canGoBack,
                    onPressed: params.onBack,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: QuestCtaAtom(
                      label: params.ctaLabel,
                      solved: params.ctaSolved,
                      onPressed: params.onCtaPressed,
                    ),
                  ),
                ],
              ),
            ),
            // Anchored to the top of the dock and drawn last, so it
            // floats just above the buttons instead of being buried.
            if (params.showSwipeHint)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SwipeHintMolecule(used: params.swipeHintUsed),
              ),
          ],
        ),
      ],
    );
  }
}
