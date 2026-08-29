import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/organisms/segment_list_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The confidence check that arrives with the answer, inside the vault.
///
/// It belongs with the answer -- it is the working that backs it up, and a
/// separate card below reads as a different subject. What kept it out was
/// length: the verification runs to several hundred characters plus a math
/// block, and that turns the payoff into a wall. So it arrives closed. One
/// line offering to show the working costs the answer nothing, and the
/// student opens it only if they want it.
///
/// The open/closed state is local. The rationale reveal lives in the bloc
/// because it has to reset when the step changes; this appears only in the
/// opened vault, at the end of the trail, where there is no step change left
/// for it to survive.
class SolutionCheckOrganism extends StatefulWidget {
  final String title;
  final List<OrderedSegment> body;
  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const SolutionCheckOrganism({
    super.key,
    required this.title,
    required this.body,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  State<SolutionCheckOrganism> createState() => _SolutionCheckOrganismState();
}

class _SolutionCheckOrganismState extends State<SolutionCheckOrganism> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.body.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('solution_check'),
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: QuestPalette.mint.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('solution_check_toggle'),
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fact_check_rounded,
                      size: 15.sp, color: QuestPalette.mint),
                  SizedBox(width: 6.w),
                  Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                      color: QuestPalette.mint,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 16.sp,
                    color: QuestPalette.mint,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              key: const Key('solution_check_body'),
              padding: EdgeInsets.only(top: 4.h),
              child: SegmentListOrganism(
                segments: widget.body,
                onEnlargeVisual: widget.onEnlargeVisual,
                imageProviderBuilder: widget.imageProviderBuilder,
              ),
            ),
        ],
      ),
    );
  }
}
