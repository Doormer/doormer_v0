import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// One length of road between two trail nodes.
///
/// Runs along whichever [axis] the trail runs along: across the bar at the top
/// of a phone, down the rail at the side of a laptop. [length] is measured
/// along the trail, and the run is always 3 thick across it.
class TrailConnectorAtom extends StatelessWidget {
  static const double thickness = 3;

  final int index;

  /// How far this run reaches along the trail.
  final double length;

  /// Clear air at each end of the run, also along the trail.
  final double margin;

  final bool lit;
  final Axis axis;

  const TrailConnectorAtom({
    super.key,
    required this.index,
    required this.length,
    required this.margin,
    required this.lit,
    this.axis = Axis.horizontal,
  });

  bool get _isHorizontal => axis == Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isHorizontal ? margin : 0,
        vertical: _isHorizontal ? 0 : margin,
      ),
      width: _isHorizontal ? length : thickness,
      height: _isHorizontal ? thickness : length,
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
          // as ground being covered rather than a light switching on. Behind
          // means left of it across a bar and above it down a rail, which is
          // why the alignment follows the axis too.
          Positioned.fill(
            // A fraction of the box, not an alignment of it: Positioned.fill
            // hands down tight constraints, and under those a widthFactor is
            // powerless -- the fill sizes to nothing and no link ever lights.
            child: AnimatedFractionallySizedBox(
              alignment:
                  _isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
              duration: MotionPolicy.duration(
                context,
                const Duration(milliseconds: 450),
              ),
              curve: Curves.easeOut,
              widthFactor: _isHorizontal ? (lit ? 1.0 : 0.0) : null,
              heightFactor: _isHorizontal ? null : (lit ? 1.0 : 0.0),
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
