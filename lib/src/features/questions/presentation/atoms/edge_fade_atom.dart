import 'package:flutter/material.dart';

/// Softens whichever end of the trail has more beyond it.
///
/// A trail that runs off the screen should look cut off, not finished — a hard
/// edge reads as "that is all the steps there are". The gradient runs along the
/// trail's own [axis] only, so the current node's glow across it passes through
/// untouched.
///
/// [start] and [end] are the two ends of the trail rather than two sides of the
/// screen: left and right across a bar, top and bottom down a rail.
class EdgeFadeAtom extends StatelessWidget {
  static const double fade = 26;

  final bool start;
  final bool end;
  final Axis axis;
  final Widget child;

  const EdgeFadeAtom({
    super.key,
    required this.start,
    required this.end,
    required this.child,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (!start && !end) return child;

    final isHorizontal = axis == Axis.horizontal;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final extent = isHorizontal ? bounds.width : bounds.height;
        final startStop = start ? fade / extent : 0.0;
        final endStop = end ? 1 - fade / extent : 1.0;
        return LinearGradient(
          begin: isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
          end: isHorizontal ? Alignment.centerRight : Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, startStop, endStop, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
