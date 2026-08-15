import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/segment_list_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The per-step "Why this works" reveal. Collapsed by default; visibility is
/// owned by the bloc so it resets predictably on a step change.
class RationaleRevealMolecule extends StatelessWidget {
  final String toggleLabel;
  final bool visible;
  final VoidCallback onToggle;
  final List<OrderedSegment> body;
  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const RationaleRevealMolecule({
    super.key,
    required this.toggleLabel,
    required this.visible,
    required this.onToggle,
    required this.body,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        InkWell(
          key: const Key('rationale_toggle'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 16.sp, color: cs.tertiary),
                SizedBox(width: 6.w),
                Text(
                  toggleLabel,
                  style: tt.labelLarge?.copyWith(
                    fontSize: 13.sp,
                    color: cs.tertiary,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  visible ? Icons.expand_less : Icons.expand_more,
                  size: 16.sp,
                  color: cs.tertiary,
                ),
              ],
            ),
          ),
        ),
        if (visible)
          Container(
            key: const Key('rationale_body'),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: SegmentListMolecule(
              segments: body,
              onEnlargeVisual: onEnlargeVisual,
              imageProviderBuilder: imageProviderBuilder,
            ),
          ),
      ],
    );
  }
}
