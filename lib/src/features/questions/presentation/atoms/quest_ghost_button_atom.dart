import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The quiet way back, outlined rather than filled so it never competes with
/// the button that moves the student forward.
class QuestGhostButtonAtom extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const QuestGhostButtonAtom({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.34,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          key: const Key('solution_back'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17.sp, color: QuestPalette.dim),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.dim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
