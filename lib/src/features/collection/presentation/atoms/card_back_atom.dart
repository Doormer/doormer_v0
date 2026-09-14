import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The face-down card: a lattice over a deep violet field.
///
/// Universal across decks. A deck may override it later, which is why the art
/// is drawn here rather than baked into the reveal.
class CardBackAtom extends StatelessWidget {
  final double? width;

  const CardBackAtom({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    // Scaled even when given explicitly, matching CollectibleCardAtom. If one
    // face scaled and the other did not, the card would change size the instant
    // it flipped on any screen that is not exactly 360pt wide.
    final w = (width ?? 118).w;
    return Container(
      width: w,
      height: w * 3 / 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color: QuestPalette.amber.withValues(alpha: 0.20),
          width: 1.w,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241D4C), Color(0xFF141030), Color(0xFF0A0818)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: CustomPaint(
          painter: LatticePainter(spacing: 11.w, strokeWidth: 1.w),
          child: Center(
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: QuestPalette.amber.withValues(alpha: 0.5),
                  width: 1.5.w,
                ),
              ),
              child: Center(
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QuestPalette.amber.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lattice itself: fine brass diagonals crossing both ways.
///
/// It is the card back's whole identity, so it is drawn rather than implied —
/// a plain gradient with an emblem is not a lattice, however close the comment
/// gets to claiming otherwise.
class LatticePainter extends CustomPainter {
  final double spacing;
  final double strokeWidth;

  const LatticePainter({required this.spacing, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = QuestPalette.amber.withValues(alpha: 0.11)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Start a full height to the left so the down-right diagonals still cover
    // the top-left corner.
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(LatticePainter oldDelegate) =>
      oldDelegate.spacing != spacing || oldDelegate.strokeWidth != strokeWidth;
}
