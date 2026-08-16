import 'package:doormer/src/core/theme/app_theme_context.dart';
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
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      key: const Key('solution_briefing'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 16.sp, color: cs.primary),
              SizedBox(width: 6.w),
              Text(
                params.title,
                style: tt.titleMedium?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
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
