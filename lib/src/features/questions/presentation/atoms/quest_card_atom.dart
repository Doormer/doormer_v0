import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The surface every piece of solution content sits on.
///
/// One card shape, used by the step, the briefing and the check, so the
/// student reads them as the same kind of thing. The violet wash falls from
/// the top-left corner and dies out before the text starts, which lifts the
/// card off the backdrop without tinting the words.
class QuestCardAtom extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Drawn over the card's top-right corner, escaping its bounds. Used for the
  /// XP sticker.
  final Widget? sticker;

  const QuestCardAtom({
    super.key,
    required this.child,
    this.padding,
    this.sticker,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuestPalette.violet.withValues(alpha: 0.34),
            QuestPalette.card.withValues(alpha: 0.94),
          ],
          stops: const [0, 0.46],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (sticker == null) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(top: -9.h, right: 12.w, child: sticker!),
      ],
    );
  }
}
