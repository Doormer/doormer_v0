import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quest_card_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/xp_sticker_atom.dart';
import 'package:doormer/src/features/questions/presentation/organisms/rationale_reveal_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/segment_list_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/rise_in_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One step of the solution, as a card.
///
/// The level label carries no total on purpose: the node trail is the only
/// progress indicator on the page.
class SolutionStepOrganism extends StatelessWidget {
  final SolutionStepParams params;

  const SolutionStepOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return QuestCardAtom(
      sticker: params.xpLabel.isEmpty
          ? null
          : XpStickerAtom(
              key: params.xpStickerKey,
              label: params.xpLabel,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Kicker, then heading, then body: the card arrives in the order it
        // wants reading.
        children: [
          RiseInAtom(
            order: 0,
            child: Text(
              params.levelLabel,
              key: const Key('step_level_label'),
              style: TextStyle(
                fontSize: 10.sp,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
                color: QuestPalette.pink,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          RiseInAtom(
            order: 1,
            child: Text(
              params.stepTitle,
              key: const Key('step_title'),
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: QuestPalette.cream,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          RiseInAtom(
            order: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentListOrganism(
                  segments: params.body,
                  onEnlargeVisual: params.onEnlargeVisual,
                  imageProviderBuilder: params.imageProviderBuilder,
                ),
                if (params.hasRationale)
                  RationaleRevealOrganism(
                    toggleLabel: params.rationaleToggleLabel,
                    visible: params.rationaleVisible,
                    onToggle: params.onToggleRationale,
                    body: params.rationale,
                    onEnlargeVisual: params.onEnlargeVisual,
                    imageProviderBuilder: params.imageProviderBuilder,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
