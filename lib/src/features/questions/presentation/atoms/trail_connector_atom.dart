import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// One length of road between two trail nodes.

class TrailConnectorAtom extends StatelessWidget {
  final int index;
  final double width;
  final double margin;
  final bool lit;

  const TrailConnectorAtom({
    super.key,
    required this.index,
    required this.width,
    required this.margin,
    required this.lit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      width: width,
      height: 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          // The lit run wipes outward from the node behind it, so a link reads
          // as ground being covered rather than a light switching on.
          Positioned.fill(
            // A fraction of the box, not an alignment of it: Positioned.fill
            // hands down tight constraints, and under those a widthFactor is
            // powerless -- the fill sizes to nothing and no link ever lights.
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              duration: MotionPolicy.duration(
                context,
                const Duration(milliseconds: 450),
              ),
              curve: Curves.easeOut,
              widthFactor: lit ? 1.0 : 0.0,
              child: DecoratedBox(
                key: Key('trail_link_fill_$index'),
                decoration: BoxDecoration(
                  color: QuestPalette.mint,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
