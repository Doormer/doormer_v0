import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/quest_card_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/note_caveat_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/segment_list_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_briefing_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The orientation screen that opens the reader.
///
/// It states what the solver read off the question and what it intends to do,
/// before the first step. The heading carries no step count: the node trail is
/// the page's only progress indicator.
class SolutionBriefingOrganism extends StatelessWidget {
  final SolutionBriefingParams params;

  const SolutionBriefingOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return QuestCardAtom(
      key: const Key('solution_briefing'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BRIEFING',
            style: TextStyle(
              fontSize: 10.sp,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: QuestPalette.pink,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 17.sp, color: QuestPalette.violet),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  params.title,
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: QuestPalette.cream,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SegmentListMolecule(
            segments: params.body,
            onEnlargeVisual: params.onEnlargeVisual,
            imageProviderBuilder: params.imageProviderBuilder,
          ),
          NoteCaveatMolecule(note: params.note),
        ],
      ),
    );
  }
}
