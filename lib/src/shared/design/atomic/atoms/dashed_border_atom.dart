import 'package:flutter/material.dart';

/// A dashed rounded-rectangle outline drawn around [child].
///
/// Flutter has no dashed [BorderSide], so the outline is stroked from path
/// metrics rather than declared on a [BoxDecoration]. Note that a dashed edge
/// cannot be faked with a [Border] anyway: giving a [BoxDecoration] both a
/// `borderRadius` and a non-uniform border throws at paint time.
///
/// The dash carries meaning rather than decoration. A shut container is drawn
/// with a broken edge and a filled one with a solid edge, so the outline itself
/// says whether the thing inside has been earned yet.
class DashedBorderAtom extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  const DashedBorderAtom({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
    this.strokeWidth = 2,
    this.dash = 6,
    this.gap = 5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dash: dash,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke so the outline lands inside the box rather than
    // straddling its edge, which would clip the outer half away.
    final inset = strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.radius != radius ||
        old.dash != dash ||
        old.gap != gap;
  }
}
