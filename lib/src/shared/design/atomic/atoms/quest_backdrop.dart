import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// The backdrop every quest screen sits on.
///
/// Three layers, taken from the prototype: a radial violet glow falling into
/// deep ink, a fine dot grid that gives the flat colour some tooth, and a pink
/// top light. Without these the screen reads as a form with a dark background
/// rather than a place.
class QuestBackdrop extends StatelessWidget {
  final Widget child;

  const QuestBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.24),
          radius: 1.2,
          colors: [
            QuestPalette.glowTop,
            QuestPalette.ink,
            QuestPalette.glowBottom,
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 320,
                  height: 250,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x4DFFABF3), Color(0x00FFABF3)],
                      stops: [0.0, 0.68],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// A 15px dot grid at low opacity. Painted rather than tiled from an asset so
/// it stays crisp at any device pixel ratio.
class _DotGridPainter extends CustomPainter {
  static const double _spacing = 15.0;
  static const double _radius = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.13);
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
