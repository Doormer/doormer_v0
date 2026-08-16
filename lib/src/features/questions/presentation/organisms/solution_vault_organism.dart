import 'package:doormer/src/core/theme/quest_palette.dart';
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
    if (revealed) {
      return Container(
        key: const Key('vault_revealed'),
        width: double.infinity,
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: QuestPalette.mint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: QuestPalette.mint, width: 2),
          boxShadow: [
            BoxShadow(
              color: QuestPalette.mint.withValues(alpha: 0.22),
              blurRadius: 26,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open_rounded,
                    size: 15.sp, color: QuestPalette.mint),
                SizedBox(width: 6.w),
                Text(
                  'CRACKED IT',
                  style: TextStyle(
                    fontSize: 10.sp,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: QuestPalette.mint,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SegmentListMolecule(
              segments: answerBody,
              onEnlargeVisual: onEnlargeVisual,
              imageProviderBuilder: imageProviderBuilder,
              emphasised: true,
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
          color: unlockable
              ? QuestPalette.amber.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: unlockable
                ? QuestPalette.amber
                : Colors.white.withValues(alpha: 0.16),
            width: unlockable ? 1.5 : 1,
          ),
          boxShadow: unlockable
              ? [
                  BoxShadow(
                    color: QuestPalette.amber.withValues(alpha: 0.24),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              unlockable ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 15.sp,
              color: unlockable ? QuestPalette.amber : QuestPalette.dim,
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                lockedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: unlockable ? QuestPalette.amber : QuestPalette.dim,
                ),
              ),
            ),
            if (unlockable)
              Icon(Icons.chevron_right_rounded,
                  size: 17.sp, color: QuestPalette.amber),
          ],
        ),
      ),
    );
  }
}
