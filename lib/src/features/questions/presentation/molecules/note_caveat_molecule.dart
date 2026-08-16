import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A one-line caveat about how the question's data was read.
///
/// Renders nothing when there is no caveat, so an absent note leaves no gap
/// and no orphan icon.
class NoteCaveatMolecule extends StatelessWidget {
  final String note;

  const NoteCaveatMolecule({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    if (note.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      key: const Key('solution_note'),
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.r),
        border: Border(left: BorderSide(color: cs.tertiary, width: 3.w)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15.sp, color: cs.tertiary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              note,
              style: tt.bodySmall?.copyWith(
                fontSize: 12.sp,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
