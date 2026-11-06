import 'dart:ui' as ui;

import 'package:doormer/src/features/levels/presentation/atoms/sparkle_atom.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'draws a pale gold sparkle in the middle of its box, with a glow that '
      'fades before the corners', (tester) async {
    const key = Key('sparkle');
    await tester.pumpWidget(const Center(
      child: RepaintBoundary(key: key, child: SparkleAtom(size: 32)),
    ));
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!;
    }))!;
    int channel(int x, int y, int index) =>
        bytes.getUint8((y * 32 + x) * 4 + index);

    // The middle: the mockup's pale gold, 0xFFFFE28A.
    expect(channel(16, 16, 3), 255);
    expect(channel(16, 16, 0), greaterThanOrEqualTo(240));
    expect(channel(16, 16, 1), inInclusiveRange(200, 245));
    expect(channel(16, 16, 2), inInclusiveRange(100, 170));
    // A corner.
    expect(channel(1, 1, 3), lessThan(64));
  });
}
