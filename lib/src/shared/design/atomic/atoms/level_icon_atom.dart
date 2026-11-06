import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';

/// One golden star, moon or sun: a level's icon, as QQ draws its levels.
///
/// Each is filled with one gold, pale at the top and deep at the bottom,
/// with a small white highlight, a soft gold glow and a faint shadow below,
/// so the three read as one family at every size. It is painted, not taken
/// from a font or an image. Screen readers skip it: whatever shows a level
/// says it in words.
class LevelIconAtom extends StatelessWidget {
  final LevelIcon icon;

  /// Its width and height, in logical pixels, so callers pass `30.w` and the
  /// like.
  final double size;

  const LevelIconAtom({super.key, required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LevelIconPainter(icon)),
    );
  }
}

/// A shape of an icon in the mockup's 24 by 24 box. The gold fills it, and
/// outlines it too when [outlined]. The gold runs down [goldBox], the box of
/// the SVG shape it comes from, as the mockup's gradient runs down each
/// shape's own box.
typedef _GoldShape = ({Path path, Rect goldBox, bool outlined});

/// A white highlight: an oval at [centre] with these [radii], turned
/// [degrees] clockwise.
typedef _Highlight = ({
  Offset centre,
  Size radii,
  double degrees,
  double opacity,
});

/// Paints one icon from the mockup's SVG, whose shapes sit in a 24 by 24 box.
class _LevelIconPainter extends CustomPainter {
  final LevelIcon icon;

  const _LevelIconPainter(this.icon);

  /// The gold, top to bottom.
  static const List<Color> _gold = [
    QuestPalette.levelGoldLight,
    QuestPalette.levelGold,
    QuestPalette.levelGoldDeep,
  ];
  static const List<double> _goldStops = [0, 0.42, 1];

  /// The glow's blur, in logical pixels at every size: the mockup's
  /// `drop-shadow(0 0 3px …)`, whose 3 px blur is a sigma of 1.5.
  static const double _glowSigma = 1.5;

  /// How far below the icon its faint shadow falls, in logical pixels.
  static const double _shadowDrop = 1;

  static const List<Offset> _starPoints = [
    Offset(12, 3.6),
    Offset(14.41, 9.48),
    Offset(20.75, 9.96),
    Offset(15.9, 14.07),
    Offset(17.41, 20.24),
    Offset(12, 16.9),
    Offset(6.59, 20.24),
    Offset(8.1, 14.07),
    Offset(3.25, 9.96),
    Offset(9.59, 9.48),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    final scale = side / 24;
    final toCanvas = Matrix4.identity()
      ..translate((size.width - side) / 2, (size.height - side) / 2)
      ..scale(scale, scale);
    Path place(Path inBox) => inBox.transform(toCanvas.storage);

    final (shapes, outline) = _shapesOf(icon);
    final outlineWidth = outline * scale;
    final placed = [for (final shape in shapes) place(shape.path)];
    final fills = Path();
    final outlines = Path();
    for (final (index, shape) in shapes.indexed) {
      fills.addPath(placed[index], Offset.zero);
      if (shape.outlined) outlines.addPath(placed[index], Offset.zero);
    }

    // Under the gold, the mockup's two drop shadows: a faint dark one just
    // below, and the gold glow all round.
    void silhouette(Paint paint, Offset offset) {
      canvas.drawPath(fills.shift(offset), paint);
      if (outlineWidth <= 0) return;
      canvas.drawPath(
        outlines.shift(offset),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }

    silhouette(
      Paint()..color = Colors.black.withValues(alpha: 0.35),
      const Offset(0, _shadowDrop),
    );
    silhouette(
      Paint()
        ..color = QuestPalette.levelGlow.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowSigma),
      Offset.zero,
    );

    for (final (index, shape) in shapes.indexed) {
      final box = MatrixUtils.transformRect(toCanvas, shape.goldBox);
      final gold = Paint()
        ..shader = ui.Gradient.linear(
          box.topCenter,
          box.bottomCenter,
          _gold,
          _goldStops,
        );
      canvas.drawPath(placed[index], gold);
      if (!shape.outlined) continue;
      canvas.drawPath(
        placed[index],
        gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (icon == LevelIcon.sun) {
      // A pale ring just inside the sun's disc.
      canvas.drawPath(
        place(Path()
          ..addOval(
              Rect.fromCircle(center: const Offset(12, 12), radius: 4.3))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9 * scale
          ..color = QuestPalette.levelGoldLight.withValues(alpha: 0.75),
      );
    }

    final highlight = _highlightOf(icon);
    final turn = Matrix4.identity()
      ..translate(highlight.centre.dx, highlight.centre.dy)
      ..rotateZ(highlight.degrees * math.pi / 180)
      ..translate(-highlight.centre.dx, -highlight.centre.dy);
    final oval = Path()
      ..addOval(Rect.fromCenter(
        center: highlight.centre,
        width: highlight.radii.width * 2,
        height: highlight.radii.height * 2,
      ));
    canvas.drawPath(
      place(oval.transform(turn.storage)),
      Paint()..color = Colors.white.withValues(alpha: highlight.opacity),
    );
  }

  /// [icon]'s shapes, and how wide the gold outlines those that have an
  /// outline.
  static (List<_GoldShape>, double) _shapesOf(LevelIcon icon) => switch (icon) {
        LevelIcon.star => (
            [
              (
                path: Path()..addPolygon(_starPoints, true),
                goldBox: _boundsOf(_starPoints),
                outlined: true,
              ),
            ],
            1.9,
          ),
        LevelIcon.moon => ([_moon()], 0.0),
        LevelIcon.sun => (
            [
              for (var ray = 0; ray < 8; ray++)
                _sunRay((ray * 45 - 90) * math.pi / 180),
              _sunDisc(),
            ],
            1.1,
          ),
      };

  /// A disc with a smaller one bitten out of its upper right.
  static _GoldShape _moon() {
    final disc = Rect.fromCircle(center: const Offset(11.4, 12.6), radius: 8.9);
    final bite = Rect.fromCircle(center: const Offset(16.9, 8.4), radius: 7.5);
    return (
      path: Path.combine(
        PathOperation.difference,
        Path()..addOval(disc),
        Path()..addOval(bite),
      ),
      goldBox: disc,
      outlined: false,
    );
  }

  /// A ray pointing at [angle], in radians clockwise from the right: a
  /// narrow triangle from the disc out to near the box's edge.
  static _GoldShape _sunRay(double angle) {
    Offset at(double radius, double angle) => Offset(
          12 + radius * math.cos(angle),
          12 + radius * math.sin(angle),
        );
    final points = [
      at(7.2, angle - 0.3),
      at(11.3, angle),
      at(7.2, angle + 0.3),
    ];
    return (
      path: Path()..addPolygon(points, true),
      goldBox: _boundsOf(points),
      outlined: true,
    );
  }

  static _GoldShape _sunDisc() {
    final disc = Rect.fromCircle(center: const Offset(12, 12), radius: 6.6);
    return (path: Path()..addOval(disc), goldBox: disc, outlined: false);
  }

  static Rect _boundsOf(List<Offset> points) =>
      (Path()..addPolygon(points, true)).getBounds();

  static _Highlight _highlightOf(LevelIcon icon) => switch (icon) {
        LevelIcon.star => (
            centre: const Offset(9.9, 9.3),
            radii: const Size(2.1, 1.1),
            degrees: -32,
            opacity: 0.6,
          ),
        LevelIcon.moon => (
            centre: const Offset(5.9, 12.2),
            radii: const Size(1.1, 3.1),
            degrees: 12,
            opacity: 0.55,
          ),
        LevelIcon.sun => (
            centre: const Offset(10.2, 9.9),
            radii: const Size(1.6, 0.9),
            degrees: -30,
            opacity: 0.6,
          ),
      };

  @override
  bool shouldRepaint(_LevelIconPainter oldDelegate) => oldDelegate.icon != icon;
}
