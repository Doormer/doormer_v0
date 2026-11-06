import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// A four-pointed sparkle (✦) in pale gold with a soft gold glow, like the
/// six that twinkle around a new level's icon. Its glow spills out of its
/// box.
class SparkleAtom extends StatelessWidget {
  /// The width and height of its box: the mockup's 16 px glyph.
  final double size;

  const SparkleAtom({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _SparklePainter()),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    final centre = size.center(Offset.zero);
    // Its four points reach 3/8 of the box out from the middle, and its
    // sides curve in almost to the middle.
    final reach = side * 0.375;
    final pinch = reach * 0.15;
    final sparkle = Path()
      ..moveTo(centre.dx, centre.dy - reach)
      ..quadraticBezierTo(
          centre.dx + pinch, centre.dy - pinch, centre.dx + reach, centre.dy)
      ..quadraticBezierTo(
          centre.dx + pinch, centre.dy + pinch, centre.dx, centre.dy + reach)
      ..quadraticBezierTo(
          centre.dx - pinch, centre.dy + pinch, centre.dx - reach, centre.dy)
      ..quadraticBezierTo(
          centre.dx - pinch, centre.dy - pinch, centre.dx, centre.dy - reach)
      ..close();
    // The mockup's 8 px text-shadow at 16 px: a blur of sigma 4.
    canvas.drawPath(
      sparkle,
      Paint()
        ..color = QuestPalette.levelGold
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side / 4),
    );
    canvas.drawPath(sparkle, Paint()..color = QuestPalette.levelPaleGold);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => false;
}
