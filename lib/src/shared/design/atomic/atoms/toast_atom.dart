import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What a toast tells the student, which picks its colour and icon.
enum ToastKind { success, error, info, warning }

/// A short message on a raised card, led by a glowing badge in the colour of
/// its [kind]. `CustomToast` floats it over the page for a moment.
///
/// Screen readers announce the message as soon as the toast appears.
class ToastAtom extends StatelessWidget {
  final String message;
  final ToastKind kind;

  const ToastAtom({super.key, required this.message, required this.kind});

  @override
  Widget build(BuildContext context) {
    final accent = switch (kind) {
      ToastKind.success => QuestPalette.mint,
      ToastKind.error => context.colorScheme.error,
      ToastKind.info => QuestPalette.markerLine,
      ToastKind.warning => QuestPalette.amber,
    };
    final icon = switch (kind) {
      ToastKind.success => Icons.check_rounded,
      ToastKind.error => Icons.error_outline_rounded,
      ToastKind.info => Icons.info_outline_rounded,
      ToastKind.warning => Icons.warning_amber_rounded,
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 12.h),
          decoration: BoxDecoration(
            color: QuestPalette.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                  boxShadow: [
                    // Outer only, so the glow rings the badge without
                    // brightening its fill.
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 12.r,
                      blurStyle: BlurStyle.outer,
                    ),
                  ],
                ),
                child: Icon(icon, size: 18.w, color: accent),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  message,
                  maxLines: 6,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: QuestPalette.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
