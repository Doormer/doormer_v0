import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/math_block_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child, {double width = 320}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the expression through flutter_math_fork',
      (tester) async {
    await tester.pumpWidget(_pump(
      const MathBlockAtom(
        latex: r'\tan\theta=\frac{3}{4}',
        semanticsLabel: 'tangent theta equals three quarters',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Math), findsOneWidget);
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

  testWidgets('shows the overflow hint when the expression is wider than the box',
      (tester) async {
    await tester.pumpWidget(_pump(
      const MathBlockAtom(
        latex:
            r'\text{Road-edge length}=\sqrt{5^2-4^2}\qquad A=5\times32=160\ \mathrm{m^2}',
        semanticsLabel: 'road edge length',
      ),
      width: 120,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('math_block_overflow_hint')), findsOneWidget);
  });

  testWidgets('the expression scrolls horizontally', (tester) async {
    await tester.pumpWidget(_pump(
      const MathBlockAtom(
        latex: r'A=5\times32=160\ \mathrm{m^2}\qquad W=95\cdot\frac{4}{5}',
        semanticsLabel: 'area',
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
