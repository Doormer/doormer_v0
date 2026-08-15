import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_step_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

SolutionStepParams _params({
  bool hasRationale = true,
  bool rationaleVisible = false,
  VoidCallback? onToggle,
}) {
  return SolutionStepParams(
    levelLabel: 'LEVEL 2',
    stepTitle: 'Find the printed rectangle width',
    body: diagramFirstOrder(const [
      TextSolutionSegment('Scale the width by four fifths.'),
    ]),
    rationale: diagramFirstOrder(const [
      TextSolutionSegment('The 5 m segment is the hypotenuse.'),
    ]),
    hasRationale: hasRationale,
    rationaleVisible: rationaleVisible,
    rationaleToggleLabel: 'Why this works',
    onToggleRationale: onToggle ?? () {},
    onEnlargeVisual: (_) {},
  );
}

Widget _pump(SolutionStepParams params) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionStepOrganism(params: params),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the level label without a total and the step title',
      (tester) async {
    await tester.pumpWidget(_pump(_params()));
    await tester.pump();

    expect(find.text('LEVEL 2'), findsOneWidget);
    expect(find.textContaining(' of '), findsNothing,
        reason: 'the trail is the only progress indicator');
    expect(find.text('Find the printed rectangle width'), findsOneWidget);
  });

  testWidgets('keeps the rationale collapsed until it is revealed',
      (tester) async {
    await tester.pumpWidget(_pump(_params()));
    await tester.pump();

    expect(find.byKey(const Key('rationale_toggle')), findsOneWidget);
    expect(find.byKey(const Key('rationale_body')), findsNothing);
    expect(find.text('The 5 m segment is the hypotenuse.'), findsNothing);
  });

  testWidgets('shows the rationale body when visible', (tester) async {
    await tester.pumpWidget(_pump(_params(rationaleVisible: true)));
    await tester.pump();

    expect(find.byKey(const Key('rationale_body')), findsOneWidget);
    expect(find.text('The 5 m segment is the hypotenuse.'), findsOneWidget);
  });

  testWidgets('tapping the toggle reports upward', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(_pump(_params(onToggle: () => toggles++)));
    await tester.pump();

    await tester.tap(find.byKey(const Key('rationale_toggle')));
    await tester.pump();

    expect(toggles, 1);
  });

  testWidgets('hides the toggle entirely when the step has no rationale',
      (tester) async {
    await tester.pumpWidget(_pump(_params(hasRationale: false)));
    await tester.pump();

    expect(find.byKey(const Key('rationale_toggle')), findsNothing);
  });
}
