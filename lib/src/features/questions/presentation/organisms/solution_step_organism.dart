import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quest_card_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/xp_sticker_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/rationale_reveal_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/segment_list_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
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
          : XpStickerAtom(label: params.xpLabel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            params.levelLabel,
            key: const Key('step_level_label'),
            style: TextStyle(
              fontSize: 10.sp,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: QuestPalette.pink,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
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
          SizedBox(height: 12.h),
          SegmentListMolecule(
            segments: params.body,
            onEnlargeVisual: params.onEnlargeVisual,
            imageProviderBuilder: params.imageProviderBuilder,
          ),
          if (params.hasRationale)
            RationaleRevealMolecule(
              toggleLabel: params.rationaleToggleLabel,
              visible: params.rationaleVisible,
              onToggle: params.onToggleRationale,
              body: params.rationale,
              onEnlargeVisual: params.onEnlargeVisual,
              imageProviderBuilder: params.imageProviderBuilder,
            ),
        ],
      ),
    );
  }
}
