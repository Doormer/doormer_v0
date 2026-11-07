import 'package:doormer/src/core/theme/css_gradients.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The level's gold panel: rounded, with a violet gradient running down at
/// the mockup's 160° and a thin gold edge. It clips what it holds, such as
/// the level's glow, to its corners.
class GoldPanelAtom extends StatelessWidget {
  final Widget child;

  const GoldPanelAtom({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: QuestPalette.levelGold.withValues(alpha: 0.22),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // The mockup's `linear-gradient(160deg, …)`.
          transform: CssAngle(160),
          colors: [
            QuestPalette.levelCardTop,
            QuestPalette.levelCardMiddle,
            QuestPalette.levelCardBottom,
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}
