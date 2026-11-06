import 'dart:math' as math;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// Golden rays behind a new level's icon, turned [turns] of a full turn
/// clockwise: fifteen rays, 9° wide and 24° apart, solid near the middle and
/// gone by 78% of the way out.
class SunburstAtom extends StatelessWidget {
  /// The width and height of the square the rays fill.
  final double size;

  /// How far the rays have turned, clockwise, in whole turns.
  final double turns;

  const SunburstAtom({super.key, required this.size, required this.turns});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SunburstPainter(turns)),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final double turns;

  const _SunburstPainter(this.turns);

  static const int _rays = 15;
  static const double _rayWidth = 9 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    if (radius <= 0) return;
    final centre = size.center(Offset.zero);
    final circle = Rect.fromCircle(center: centre, radius: radius);
    final rays = Path();
    for (var ray = 0; ray < _rays; ray++) {
      // From straight up, where the mockup's conic gradient starts.
      final start = (turns + ray / _rays) * 2 * math.pi - math.pi / 2;
      rays
        ..moveTo(centre.dx, centre.dy)
        ..arcTo(circle, start, _rayWidth, false)
        ..close();
    }
    canvas.saveLayer(circle, Paint());
    canvas.drawPath(
      rays,
      Paint()..color = QuestPalette.levelPaleGold.withValues(alpha: 0.26),
    );
    // Keeps the rays only as far as the mask lets them: all of them to 30%
    // of the way out, then less and less, and none past 78%.
    canvas.drawRect(
      circle,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const RadialGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.3, 0.78],
        ).createShader(circle),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunburstPainter oldDelegate) =>
      oldDelegate.turns != turns;
}
