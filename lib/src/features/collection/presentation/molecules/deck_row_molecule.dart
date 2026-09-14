import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../atoms/progress_ring_atom.dart';
import '../params/deck_row_params.dart';

/// One deck in the list. The same widget is the phone's landing screen and the
/// desktop rail — only [DeckRowParams.showFlag] differs.
class DeckRowMolecule extends StatelessWidget {
  final DeckRowParams params;

  const DeckRowMolecule({super.key, required this.params});

  Widget? _flag() {
    if (!params.showFlag) return null;
    if (params.isComplete) {
      return const _Pill(
        label: 'Complete',
        colour: QuestPalette.mint,
      );
    }
    if (params.isUntouched) {
      return const _Pill(label: 'New', colour: QuestPalette.amber);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final flag = _flag();
    return InkWell(
      onTap: params.onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          color: params.isSelected
              ? QuestPalette.amber.withValues(alpha: 0.13)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            ProgressRingAtom(held: params.held, total: params.total),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                params.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight:
                      params.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: params.isSelected
                      ? QuestPalette.cream
                      : QuestPalette.body,
                ),
              ),
            ),
            if (flag != null) ...[flag, SizedBox(width: 8.w)],
            Text(
              '${params.held}/${params.total}',
              style: TextStyle(fontSize: 10.5.sp, color: QuestPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color colour;

  const _Pill({required this.label, required this.colour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: colour,
        ),
      ),
    );
  }
}
