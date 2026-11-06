import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Runs a top-to-bottom [LinearGradient] at a CSS angle in [degrees]
/// (0 is up, 90 right). Like CSS, it puts the first colour on one corner
/// and the last on the opposite one. Use it to copy a mockup's
/// `linear-gradient(<degrees>deg, …)`.
class CssAngle extends GradientTransform {
  final double degrees;

  const CssAngle(this.degrees);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final angle = degrees * math.pi / 180;
    // CSS's gradient line: long enough that lines across it at its two
    // ends pass through the corners.
    final length = (bounds.width * math.sin(angle)).abs() +
        (bounds.height * math.cos(angle)).abs();
    final centre = bounds.center;
    return Matrix4.identity()
      ..translate(centre.dx, centre.dy)
      ..rotateZ(angle - math.pi)
      ..scale(1.0, length / bounds.height)
      ..translate(-centre.dx, -centre.dy);
  }
}

/// Stretches a [RadialGradient] from a circle into the ellipse that fills
/// its box, as CSS's `radial-gradient(closest-side, …)` does. Flutter
/// draws a circle as wide as the box's shorter side.
class FillBoxAsEllipse extends GradientTransform {
  const FillBoxAsEllipse();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final centre = bounds.center;
    return Matrix4.identity()
      ..translate(centre.dx, centre.dy)
      ..scale(bounds.width / bounds.shortestSide,
          bounds.height / bounds.shortestSide)
      ..translate(-centre.dx, -centre.dy);
  }
}
