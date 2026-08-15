import 'package:doormer/src/core/theme/app_theme_context.dart';
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
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
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
          Text(
            params.levelLabel,
            key: const Key('step_level_label'),
            style: tt.labelSmall?.copyWith(
              fontSize: 11.sp,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            params.stepTitle,
            key: const Key('step_title'),
            style: tt.titleMedium?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
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
