import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How far the student is through their level: a gold fill, with a soft
/// glow, along a faint track, and the next level's icon, faded, waiting at
/// the end.
class LevelProgressBarMolecule extends StatelessWidget {
  /// How much of the track the gold fills, from 0 to 1.
  final double fill;

  /// The icon the next level adds.
  final LevelIcon nextLevelIcon;

  const LevelProgressBarMolecule({
    super.key,
    required this.fill,
    required this.nextLevelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6.r);
    final height = 10.h;
    final iconSize = 20.w;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: const ValueKey('level-bar-track'),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: radius,
              ),
            ),
          ),
          if (fill > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill.clamp(0.0, 1.0),
                child: DecoratedBox(
                  key: const ValueKey('level-bar-fill'),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: const LinearGradient(
                      colors: [
                        QuestPalette.levelGoldDeep,
                        QuestPalette.levelGold,
                        QuestPalette.levelGoldLight,
                      ],
                      stops: [0, 0.7, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: QuestPalette.levelGlow.withValues(alpha: 0.45),
                        blurRadius: 10.r,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Centred on the track, and hanging 6 past its end.
          Positioned(
            right: -6.w,
            top: (height - iconSize) / 2,
            child: Opacity(
              opacity: 0.35,
              child: LevelIconAtom(icon: nextLevelIcon, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }
}
