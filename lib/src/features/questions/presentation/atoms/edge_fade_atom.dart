import 'package:flutter/material.dart';

/// Softens whichever end of the trail has more beyond it.
///
/// A trail that runs off the screen should look cut off, not finished — a hard
/// edge reads as "that is all the steps there are". The gradient is horizontal
/// only, so the current node's vertical glow passes through untouched.
class EdgeFadeAtom extends StatelessWidget {
  static const double _fade = 26;

  final bool left;
  final bool right;
  final Widget child;

  const EdgeFadeAtom({
    super.key,
    required this.left,
    required this.right,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!left && !right) return child;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final leftStop = left ? _fade / bounds.width : 0.0;
        final rightStop = right ? 1 - _fade / bounds.width : 1.0;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, leftStop, rightStop, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
