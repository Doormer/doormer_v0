import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/segment_list_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The confidence check that arrives with the answer.
///
/// It sits beside the vault rather than inside it. The vault is a
/// high-contrast panel whose job is to make one short answer land; the
/// verification runs to several hundred characters plus a math block, and
/// inside the vault it would turn the payoff into a wall.
class SolutionCheckOrganism extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (body.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      key: const Key('solution_check'),
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 16.sp, color: cs.tertiary),
              SizedBox(width: 6.w),
              Text(
                title,
                style: tt.labelLarge?.copyWith(
                  fontSize: 12.sp,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: cs.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SegmentListMolecule(
            segments: body,
            onEnlargeVisual: onEnlargeVisual,
            imageProviderBuilder: imageProviderBuilder,
          ),
        ],
      ),
    );
  }
}
