import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/segment_list_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The final-answer vault. A one-line strip while locked so it does not squat
/// at full size, an unlockable panel on the last step, then the answer itself.
class SolutionVaultOrganism extends StatelessWidget {
  final bool revealed;
  final bool unlockable;
  final String lockedLabel;
  final List<OrderedSegment> answerBody;
  final VoidCallback onReveal;
  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const SolutionVaultOrganism({
    super.key,
    required this.revealed,
    required this.unlockable,
    required this.lockedLabel,
    required this.answerBody,
    required this.onReveal,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (revealed) {
      return Container(
        key: const Key('vault_revealed'),
        width: double.infinity,
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: cs.tertiary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open, size: 16.sp, color: cs.onTertiaryContainer),
                SizedBox(width: 6.w),
                Text(
                  'Final answer',
                  style: tt.labelLarge?.copyWith(
                    fontSize: 12.sp,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SegmentListMolecule(
              segments: answerBody,
              onEnlargeVisual: onEnlargeVisual,
              imageProviderBuilder: imageProviderBuilder,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      key: const Key('vault_locked'),
      onTap: unlockable ? onReveal : null,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: unlockable ? cs.tertiaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: unlockable ? cs.tertiary : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 15.sp,
              color: unlockable ? cs.onTertiaryContainer : cs.onSurfaceVariant,
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                lockedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelLarge?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color:
                      unlockable ? cs.onTertiaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
