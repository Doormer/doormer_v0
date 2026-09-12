import 'package:doormer/src/shared/design/atomic/atoms/punch_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Object? trigger, {bool motion = true}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: !motion),
      child: Scaffold(
        body: Center(
          child: PunchAtom(
            trigger: trigger,
            child: const Text('130 XP'),
          ),
        ),
      ),
    ),
  );
}

double _scaleOf(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(
      of: find.text('130 XP'),
      matching: find.byType(Transform),
    ),
  );
  var scale = 1.0;
  for (final transform in transforms) {
    scale *= transform.transform.entry(0, 0);
  }
  return scale;
}

void main() {
  testWidgets('does not punch on first build', (tester) async {
    await tester.pumpWidget(_pump(1));
    // Two pumps: a controller started in the first frame does not leave zero
    // until the tick after it, so a single pump reads 1.0 whatever happens.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(_scaleOf(tester), 1.0,
        reason: 'arriving at a page is not an event');
  });

  testWidgets('swells when the trigger changes', (tester) async {
    await tester.pumpWidget(_pump(1));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_pump(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(_scaleOf(tester), greaterThan(1.05));

    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1.0, reason: 'the punch has to land back');
  });

  testWidgets('stays still under reduced motion', (tester) async {
    await tester.pumpWidget(_pump(1, motion: false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_pump(2, motion: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(_scaleOf(tester), 1.0);
  });
}
