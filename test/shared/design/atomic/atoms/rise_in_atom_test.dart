import 'package:doormer/src/shared/design/atomic/atoms/rise_in_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({required bool motion, required Widget child}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: !motion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    ),
  );
}

double _opacityOf(WidgetTester tester, String text) {
  final opacity = tester.widgetList<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
  );
  return opacity.fold<double>(1, (value, widget) => value * widget.opacity);
}

void main() {
  testWidgets('leaves the child in place when motion is off', (tester) async {
    await tester.pumpWidget(_pump(
      motion: false,
      child: const RiseInAtom(order: 2, child: Text('Find the slope')),
    ));
    await tester.pump();

    expect(find.text('Find the slope'), findsOneWidget);
    expect(_opacityOf(tester, 'Find the slope'), 1.0,
        reason: 'switching motion off must cost movement, never information');
    expect(
      find.ancestor(
        of: find.text('Find the slope'),
        matching: find.byType(Transform),
      ),
      findsNothing,
      reason: 'nothing may be left offset from where it belongs',
    );
  });

  testWidgets('rises from below into full view', (tester) async {
    await tester.pumpWidget(_pump(
      motion: true,
      child: const RiseInAtom(order: 0, child: Text('Find the slope')),
    ));
    await tester.pump();

    expect(_opacityOf(tester, 'Find the slope'), lessThan(0.1));
    final start = tester.getTopLeft(find.text('Find the slope')).dy;

    await tester.pumpAndSettle();

    expect(_opacityOf(tester, 'Find the slope'), 1.0);
    final end = tester.getTopLeft(find.text('Find the slope')).dy;
    expect(end, lessThan(start), reason: 'it should have travelled upward');
  });

  testWidgets('a later piece is still arriving when an earlier one has landed',
      (tester) async {
    await tester.pumpWidget(_pump(
      motion: true,
      child: const Column(
        children: [
          RiseInAtom(order: 0, child: Text('kicker')),
          RiseInAtom(order: 2, child: Text('body')),
        ],
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(_opacityOf(tester, 'kicker'), 1.0);
    expect(_opacityOf(tester, 'body'), lessThan(1.0),
        reason: 'the stagger is what says in which order to read');

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'body'), 1.0);
  });
}
