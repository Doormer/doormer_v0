import 'dart:ui' as ui;

import 'package:doormer/src/shared/design/atomic/atoms/level_icon_atom.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A pixel's red, green, blue and alpha, each 0 to 255.
typedef _Pixel = ({int r, int g, int b, int a});

/// Draws [icon] 48 across, twice the mockup's 24 by 24 box, and answers the
/// pixel under any point (x, y) of that box.
Future<_Pixel Function(double x, double y)> _draw(
  WidgetTester tester,
  LevelIcon icon,
) async {
  const key = Key('icon');
  await tester.pumpWidget(Center(
    child: RepaintBoundary(
      key: key,
      child: LevelIconAtom(icon: icon, size: 48),
    ),
  ));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!;
  }))!;
  return (x, y) {
    final offset = ((2 * y).floor() * 48 + (2 * x).floor()) * 4;
    return (
      r: bytes.getUint8(offset),
      g: bytes.getUint8(offset + 1),
      b: bytes.getUint8(offset + 2),
      a: bytes.getUint8(offset + 3),
    );
  };
}

/// Solid gold: opaque, with much red, a good deal of green and little blue.
final _isGold = predicate<_Pixel>(
  (pixel) =>
      pixel.a == 255 && pixel.r >= 220 && pixel.g >= 140 && pixel.b <= 110,
  'solid gold',
);

/// Nothing drawn there, or next to nothing.
final _isClear = predicate<_Pixel>((pixel) => pixel.a <= 30, 'clear');

void main() {
  testWidgets('a star is gold, with nothing between its points',
      (tester) async {
    final pixelAt = await _draw(tester, LevelIcon.star);

    expect(pixelAt(12, 12), _isGold, reason: 'the middle');
    expect(pixelAt(12, 21), _isClear, reason: 'between the lower points');
    expect(pixelAt(1, 1), _isClear, reason: 'a corner of the box');
  });

  testWidgets('a moon is a gold crescent, with nothing in its bite',
      (tester) async {
    final pixelAt = await _draw(tester, LevelIcon.moon);

    expect(pixelAt(7, 17), _isGold, reason: 'the body of the crescent');
    expect(pixelAt(16.9, 8.4), _isClear, reason: 'the bite');
    expect(pixelAt(1, 1), _isClear, reason: 'a corner of the box');
  });

  testWidgets('a sun is a gold disc with rays, and nothing between the rays',
      (tester) async {
    final pixelAt = await _draw(tester, LevelIcon.sun);

    expect(pixelAt(12, 12), _isGold, reason: 'the disc');
    expect(pixelAt(12, 2.5), _isGold, reason: 'the top ray, near its tip');
    expect(pixelAt(16.25, 2.25), _isClear, reason: 'between two rays');
  });

  testWidgets('the gold runs from pale at the top to deep at the bottom',
      (tester) async {
    final pixelAt = await _draw(tester, LevelIcon.star);

    final top = pixelAt(12.25, 6.25);
    final bottom = pixelAt(12.25, 16.25);
    expect(top.b, greaterThan(bottom.b + 60), reason: 'paler at the top');
    expect(top.g, greaterThan(bottom.g));
  });
}
