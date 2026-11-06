import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:doormer/src/features/levels/presentation/atoms/sunburst_atom.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws a sunburst 200 across, turned [turns], and answers how opaque it is
/// at [degrees] clockwise from straight up and [radius] from its middle.
Future<int Function(double degrees, double radius)> _draw(
  WidgetTester tester,
  double turns,
) async {
  const key = Key('rays');
  await tester.pumpWidget(Center(
    child: RepaintBoundary(
      key: key,
      child: SunburstAtom(size: 200, turns: turns),
    ),
  ));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!;
  }))!;
  return (degrees, radius) {
    final angle = (degrees - 90) * math.pi / 180;
    final x = (100 + radius * math.cos(angle)).floor();
    final y = (100 + radius * math.sin(angle)).floor();
    return bytes.getUint8((y * 200 + x) * 4 + 3);
  };
}

void main() {
  testWidgets('draws fifteen rays, 9° wide and 24° apart, which turn',
      (tester) async {
    final still = await _draw(tester, 0);

    expect(still(4.5, 28), greaterThan(30), reason: 'in the first ray');
    expect(still(16.5, 28), 0, reason: 'between the first two rays');
    expect(still(28.5, 28), greaterThan(30), reason: 'in the second ray');

    final turned = await _draw(tester, 12 / 360);

    expect(turned(4.5, 28), 0, reason: 'the first ray has moved on');
    expect(turned(16.5, 28), greaterThan(30), reason: 'to here');
  });

  testWidgets('fades out before the ends of its rays', (tester) async {
    final rays = await _draw(tester, 0);

    expect(rays(4.5, 28), greaterThan(30), reason: 'solid near the middle');
    expect(rays(4.5, 85), lessThan(10), reason: 'gone by 78% of the way out');
  });
}
