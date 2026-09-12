import 'package:doormer/src/shared/design/atomic/atoms/dashed_border_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('paints without throwing on a rounded box', (tester) async {
    // A dashed edge cannot be expressed as a Border, because a BoxDecoration
    // carrying both a borderRadius and a non-uniform border throws at paint
    // time rather than at analysis time. This guards the painter that replaces
    // it.
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: DashedBorderAtom(
            color: Color(0xFFFFD84D),
            radius: 14,
            child: SizedBox(width: 200, height: 60),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out at exactly its child size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: DashedBorderAtom(
            color: Color(0xFFFFD84D),
            radius: 14,
            child: SizedBox(width: 200, height: 60),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(DashedBorderAtom)),
      const Size(200, 60),
      reason: 'the outline is painted over the child, so adding it must not '
          'shift the surrounding layout',
    );
  });
}
