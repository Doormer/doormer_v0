import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The one big button at the foot of a quest page.
///
/// It carries a hard 3px bottom edge rather than a blur. A blurred drop shadow
/// reads as a floating card; a solid edge reads as a key you can press, which
/// is the whole point of the last control on the page.
///
/// [solved] turns it mint. That is a fact about the page, not about the
/// button, so it is passed in rather than inferred from being disabled —
/// a disabled button quietly turning green is not a thing anyone expects.
class QuestCtaAtom extends StatelessWidget {
  final String label;
  final bool solved;
  final VoidCallback? onPressed;

  const QuestCtaAtom({
    super.key,
    required this.label,
    required this.onPressed,
    this.solved = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final accent = solved ? QuestPalette.mint : QuestPalette.violet;
    final edge = solved ? _solvedEdge : _actionEdge;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('solution_cta'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(color: edge, offset: const Offset(0, 3)),
                BoxShadow(
                  color: accent.withValues(alpha: 0.42),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: solved ? QuestPalette.onMint : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The pressed-in underside of each accent, a few steps darker than the face.
  static const Color _actionEdge = Color(0xFF4A2FD1);
  static const Color _solvedEdge = Color(0xFF00A874);
}
