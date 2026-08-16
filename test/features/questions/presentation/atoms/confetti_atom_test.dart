import 'package:doormer/src/features/questions/presentation/atoms/confetti_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({bool motion = true}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: !motion),
      child: const Scaffold(
        body: SizedBox(
          width: 300,
          height: 300,
          child: ConfettiAtom(seed: 7),
        ),
      ),
    ),
  );
}

int _pieces(WidgetTester tester) => tester
    .widgetList<Container>(find.descendant(
      of: find.byType(ConfettiAtom),
      matching: find.byType(Container),
    ))
    .length;

void main() {
  group('ConfettiAtom', () {
    testWidgets('throws paper across the width once it starts', (tester) async {
      await tester.pumpWidget(_pump());
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(_pieces(tester), greaterThan(10),
          reason: 'a handful of pieces is a glitch, not a celebration');

      final lefts = tester
          .widgetList<Positioned>(find.descendant(
            of: find.byType(ConfettiAtom),
            matching: find.byType(Positioned),
          ))
          .map((p) => p.left!)
          .toList();
      expect(lefts.reduce((a, b) => a < b ? a : b), lessThan(100));
      expect(lefts.reduce((a, b) => a > b ? a : b), greaterThan(200),
          reason: 'paper that all lands in one column is a leak, not a burst');

      await tester.pumpAndSettle();
    });

    testWidgets('falls downward as it goes', (tester) async {
      await tester.pumpWidget(_pump());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      final early = tester
          .widgetList<Positioned>(find.descendant(
            of: find.byType(ConfettiAtom),
            matching: find.byType(Positioned),
          ))
          .map((p) => p.top!)
          .reduce((a, b) => a + b);

      await tester.pump(const Duration(milliseconds: 500));
      final later = tester
          .widgetList<Positioned>(find.descendant(
            of: find.byType(ConfettiAtom),
            matching: find.byType(Positioned),
          ))
          .map((p) => p.top!)
          .reduce((a, b) => a + b);

      expect(later, greaterThan(early));
      await tester.pumpAndSettle();
    });

    testWidgets('leaves nothing behind once it has landed', (tester) async {
      await tester.pumpWidget(_pump());
      await tester.pumpAndSettle();

      expect(_pieces(tester), 0,
          reason: 'confetti that keeps falling stops being a celebration and '
              'becomes weather');
    });

    testWidgets('never runs under reduced motion', (tester) async {
      await tester.pumpWidget(_pump(motion: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(_pieces(tester), 0);
    });

    testWidgets('is declared non-interactive so it cannot intercept a tap',
        (tester) async {
      await tester.pumpWidget(_pump());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(
        find.descendant(
          of: find.byType(ConfettiAtom),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
        reason: 'the burst covers the thing it is celebrating; it must not '
            'stand between the student and it',
      );
      expect(
        tester
            .widget<IgnorePointer>(find.descendant(
              of: find.byType(ConfettiAtom),
              matching: find.byType(IgnorePointer),
            ))
            .ignoring,
        isTrue,
      );

      await tester.pumpAndSettle();
    });
  });
}
