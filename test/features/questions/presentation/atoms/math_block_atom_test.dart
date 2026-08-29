import 'dart:math' as math;

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/math_block_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real payload's longest expression. It measures roughly 1.5x the width
/// of a phone card, which is what used to force the student to drag it
/// sideways.
const longExpression =
    r'\text{Road-edge length}=\sqrt{32^2+24^2}=40\ \mathrm{m}';

Widget _pump(Widget child, {double width = 358, bool motion = false}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: Scaffold(
          body: Center(child: SizedBox(width: width, child: child)),
        ),
      ),
    ),
  );
}

/// Sizes the surface like a phone, so that `.sp` resolves to the type size a
/// student actually reads and the widths under test are the real ones.
void _onAPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Groups the rendered clauses into the lines they were laid out on. Two
/// clauses sharing a line overlap vertically; two on different lines cannot.
int _lineCount(WidgetTester tester) {
  final boxes = find
      .byType(Math)
      .evaluate()
      .map((element) => element.renderObject! as RenderBox)
      .toList();
  var lines = 0;
  var bottom = double.negativeInfinity;
  for (final box in boxes) {
    final top = box.localToGlobal(Offset.zero).dy;
    if (top >= bottom) lines++;
    bottom = math.max(bottom, top + box.size.height);
  }
  return lines;
}

void _sheenTests() {
  const expression = MathBlockAtom(
    latex: r'\tan\theta=\frac{3}{4}',
    semanticsLabel: 'tangent theta equals three quarters',
  );

  group('the sheen', () {
    testWidgets('passes over the expression once when it arrives',
        (tester) async {
      await tester.pumpWidget(_pump(expression, motion: true));
      // The controller starts in a post-frame callback, so the first pump only
      // schedules it. Sampling now would read the zeroth tick.
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('math_block_sheen')), findsNothing,
          reason: 'the sweep waits for the card to arrive rather than racing '
              'it');

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('math_block_sheen')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('math_block_sheen')), findsNothing,
          reason: 'a permanent shimmer competes with the maths, and the maths '
              'must win');
    });

    testWidgets('travels across rather than glinting in place', (tester) async {
      await tester.pumpWidget(_pump(expression, motion: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final early = tester
          .widget<Transform>(find.ancestor(
            of: find.byKey(const Key('math_block_sheen')),
            matching: find.byType(Transform),
          ))
          .transform
          .getTranslation()
          .x;

      await tester.pump(const Duration(milliseconds: 300));
      final later = tester
          .widget<Transform>(find.ancestor(
            of: find.byKey(const Key('math_block_sheen')),
            matching: find.byType(Transform),
          ))
          .transform
          .getTranslation()
          .x;

      expect(later, greaterThan(early));
      await tester.pumpAndSettle();
    });

    testWidgets('never runs under reduced motion', (tester) async {
      await tester.pumpWidget(_pump(expression));
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(const Key('math_block_sheen')), findsNothing);
      }
    });
  });
}

void _wrappingTests() {
  group('long working', () {
    testWidgets('wraps onto the next line instead of running off the card',
        (tester) async {
      _onAPhone(tester);
      await tester.pumpWidget(_pump(const MathBlockAtom(
        latex: longExpression,
        semanticsLabel: 'road edge length',
      )));
      await tester.pumpAndSettle();

      expect(_lineCount(tester), greaterThan(1));
      expect(tester.getSize(find.byKey(const Key('math_block_flow'))).width,
          lessThanOrEqualTo(358),
          reason: 'nothing is left hanging off the side of the card');
    });

    testWidgets('stops asking the student to scroll it', (tester) async {
      _onAPhone(tester);
      await tester.pumpWidget(_pump(const MathBlockAtom(
        latex: longExpression,
        semanticsLabel: 'road edge length',
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('math_block_overflow_hint')), findsNothing);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        lessThan(2),
      );
    });

    testWidgets('keeps an expression that fits on one line', (tester) async {
      // Breaking working that had no need to break would scatter a short
      // answer down the page for nothing.
      _onAPhone(tester);
      await tester.pumpWidget(_pump(const MathBlockAtom(
        latex: r'A=5\times32=160\ \mathrm{m^2}',
        semanticsLabel: 'area',
      )));
      await tester.pumpAndSettle();

      expect(_lineCount(tester), 1);
    });

    testWidgets('scrolls only what it cannot break', (tester) async {
      // A run of words has no relation in it to break at. That is the one case
      // the scroll view is still for, and it still says so.
      _onAPhone(tester);
      await tester.pumpWidget(_pump(
        const MathBlockAtom(
          latex: r'\text{Road-edge length}',
          semanticsLabel: 'road edge length',
        ),
        width: 200,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('math_block_overflow_hint')), findsOneWidget);
    });
  });
}

void main() {
  _sheenTests();
  _wrappingTests();

  testWidgets('renders the expression through flutter_math_fork',
      (tester) async {
    await tester.pumpWidget(_pump(
      const MathBlockAtom(
        latex: r'\tan\theta=\frac{3}{4}',
        semanticsLabel: 'tangent theta equals three quarters',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Math), findsWidgets);
    expect(find.text(r'\tan\theta=\frac{3}{4}'), findsNothing,
        reason: 'the raw LaTeX must never reach the student');
  });

  testWidgets('hides the overflow hint when the expression fits',
      (tester) async {
    await tester.pumpWidget(_pump(
      const MathBlockAtom(latex: r'x=1', semanticsLabel: 'x equals one'),
      width: 320,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('math_block_overflow_hint')), findsNothing);
  });

  testWidgets('the expression scrolls horizontally', (tester) async {
    await tester.pumpWidget(_pump(
      const MathBlockAtom(
        latex: r'\text{Road-edge length}',
        semanticsLabel: 'road edge length',
      ),
      width: 100,
    ));
    await tester.pumpAndSettle();

    final scrollable = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('math_block_scroll')),
    );
    expect(scrollable.scrollDirection, Axis.horizontal);
  });
}
