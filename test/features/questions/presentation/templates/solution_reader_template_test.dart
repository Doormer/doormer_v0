import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_step_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_reader_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_reader_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _document = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Find the road slope', body: [
      TextSolutionSegment('Let theta be the angle.'),
    ]),
    SolutionStep(title: 'Scale the width', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    TextSolutionSegment('The paved area is 160 square metres.'),
  ]),
);

Widget _pump(SolutionReaderParams params) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: SolutionReaderTemplate(params: params),
    ),
  );
}

SolutionReaderParams _params(
  SolutionReaderReady state, {
  VoidCallback? onNext,
  VoidCallback? onBack,
}) {
  return SolutionReaderParams(
    content: solutionReaderContent(state),
    onNext: onNext ?? () {},
    onBack: onBack ?? () {},
    onToggleRationale: () {},
    onRevealAnswer: () {},
    onEnlargeVisual: (_) {},
  );
}

void main() {
  testWidgets('owns exactly one Scaffold and pins the trail and the CTA',
      (tester) async {
    await tester.pumpWidget(
      _pump(_params(const SolutionReaderReady(document: _document))),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SolutionTrailMolecule), findsOneWidget);
    expect(find.byType(SolutionStepOrganism), findsOneWidget);
    expect(find.byKey(const Key('solution_cta')), findsOneWidget);

    final trailY = tester.getTopLeft(find.byType(SolutionTrailMolecule)).dy;
    final ctaY = tester.getTopLeft(find.byKey(const Key('solution_cta'))).dy;
    final scrollY = tester.getTopLeft(find.byKey(const Key('solution_scroll'))).dy;

    expect(trailY, lessThan(scrollY), reason: 'the trail sits above the scroll');
    expect(ctaY, greaterThan(scrollY), reason: 'the CTA sits below the scroll');
  });

  testWidgets('the CTA reports upward and reads Next step mid-solution',
      (tester) async {
    var next = 0;
    await tester.pumpWidget(_pump(_params(
      const SolutionReaderReady(document: _document),
      onNext: () => next++,
    )));
    await tester.pump();

    expect(find.text('Next step'), findsOneWidget);

    await tester.tap(find.byKey(const Key('solution_cta')));
    await tester.pump();

    expect(next, 1);
  });

  testWidgets('the back control is disabled on the first step', (tester) async {
    var back = 0;
    await tester.pumpWidget(_pump(_params(
      const SolutionReaderReady(document: _document),
      onBack: () => back++,
    )));
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('solution_back')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(back, 0);
  });

  testWidgets('reads Reveal answer on the last step', (tester) async {
    await tester.pumpWidget(_pump(_params(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    )));
    await tester.pump();

    expect(find.text('Reveal answer'), findsOneWidget);
  });
}
