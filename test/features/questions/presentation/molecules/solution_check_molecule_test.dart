import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/math_block_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_check_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(List<OrderedSegment> body) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionCheckMolecule(
            title: 'Check it',
            body: body,
            onEnlargeVisual: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('offers the working without spending the answer on it',
      (tester) async {
    await tester.pumpWidget(_pump(diagramFirstOrder(const [
      TextSolutionSegment('Both routes give 160 square metres.'),
      MathSolutionSegment(latex: r'A=40\times4=160', alt: 'area'),
    ])));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_check')), findsOneWidget);
    expect(find.text('CHECK IT'), findsOneWidget,
        reason: 'the heading is a kicker, set in caps like every other kicker');
    expect(find.byKey(const Key('solution_check_body')), findsNothing,
        reason: 'several hundred characters of working would bury the answer '
            'it is there to support');
    expect(find.text('Both routes give 160 square metres.'), findsNothing);

    await tester.tap(find.byKey(const Key('solution_check_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_check_body')), findsOneWidget);
    expect(find.text('Both routes give 160 square metres.'), findsOneWidget);
    expect(find.byType(MathBlockAtom), findsOneWidget);
  });

  testWidgets('closes again on a second tap', (tester) async {
    await tester.pumpWidget(_pump(diagramFirstOrder(const [
      TextSolutionSegment('Both routes give 160 square metres.'),
    ])));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('solution_check_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('solution_check_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_check_body')), findsNothing);
  });

  testWidgets('renders nothing at all when there is no verification',
      (tester) async {
    await tester.pumpWidget(_pump(const []));
    await tester.pump();

    expect(find.byKey(const Key('solution_check')), findsNothing);
    expect(find.byKey(const Key('solution_check_toggle')), findsNothing,
        reason: 'an absent section must not leave an orphan heading');
  });
}
