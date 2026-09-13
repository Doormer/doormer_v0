import 'package:doormer/src/features/collection/presentation/atoms/card_back_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) =>
          MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('draws a lattice, not just a gradient', (tester) async {
    await tester.pumpWidget(_host(const CardBackAtom(width: 118)));
    final paints = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is LatticePainter);
    expect(paints, isNotEmpty,
        reason: 'the lattice is the card back, not decoration on it');
  });

  testWidgets('keeps a 2:3 shape', (tester) async {
    await tester.pumpWidget(_host(const CardBackAtom(width: 118)));
    final size = tester.getSize(find.byType(CardBackAtom));
    expect(size.height / size.width, closeTo(3 / 2, 0.01));
  });

  testWidgets('paints without throwing', (tester) async {
    await tester.pumpWidget(_host(const CardBackAtom(width: 240)));
    expect(tester.takeException(), isNull);
  });
}
