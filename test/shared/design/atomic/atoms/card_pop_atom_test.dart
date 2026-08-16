import 'package:doormer/src/shared/design/atomic/atoms/card_pop_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({required bool motion, Key? key}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: !motion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: CardPopAtom(key: key, child: const Text('Scale the width')),
      ),
    ),
  );
}

/// The painted scale, which is what the pop changes -- a Transform leaves the
/// child's layout size alone, so measuring the box would prove nothing.
double _scaleOf(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .ancestor(
          of: find.text('Scale the width'),
          matching: find.byType(Transform),
        )
        .first,
  );
  // Not getMaxScaleOnAxis: Transform.scale leaves z at 1, which would swamp
  // an x scale below 1 and report a pop that never happened.
  return transform.transform.entry(0, 0);
}

double _opacityOf(WidgetTester tester) {
  final opacity = tester.widgetList<Opacity>(
    find.ancestor(
      of: find.text('Scale the width'),
      matching: find.byType(Opacity),
    ),
  );
  return opacity.fold<double>(1, (value, widget) => value * widget.opacity);
}

void main() {
  testWidgets('shows the card outright when motion is off', (tester) async {
    await tester.pumpWidget(_pump(motion: false));
    await tester.pump();

    expect(find.text('Scale the width'), findsOneWidget);
    expect(_opacityOf(tester), 1.0);
    expect(
      find.ancestor(
        of: find.text('Scale the width'),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('pops from small and faint to full size', (tester) async {
    await tester.pumpWidget(_pump(motion: true));
    await tester.pump();

    expect(_opacityOf(tester), lessThan(0.5));
    expect(_scaleOf(tester), closeTo(0.96, 0.005));

    await tester.pumpAndSettle();

    expect(_opacityOf(tester), 1.0);
    expect(_scaleOf(tester), closeTo(1.0, 0.005));
  });

  testWidgets('replays when the key changes and not when it does not',
      (tester) async {
    await tester.pumpWidget(_pump(motion: true, key: const ValueKey('LEVEL 1')));
    await tester.pumpAndSettle();
    expect(_opacityOf(tester), 1.0);

    await tester.pumpWidget(_pump(motion: true, key: const ValueKey('LEVEL 1')));
    await tester.pump();
    expect(_opacityOf(tester), 1.0,
        reason: 'a rationale toggle must not re-pop the card');

    await tester.pumpWidget(_pump(motion: true, key: const ValueKey('LEVEL 2')));
    await tester.pump();
    expect(_opacityOf(tester), lessThan(0.5),
        reason: 'a new step is a new card arriving');
  });
}
