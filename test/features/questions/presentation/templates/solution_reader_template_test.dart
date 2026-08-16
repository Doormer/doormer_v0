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

const _briefedDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Find the road slope', body: []),
    SolutionStep(title: 'Scale the width', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    TextSolutionSegment('The paved area is 160 square metres.'),
  ]),
  approach: SolutionSection(body: [
    TextSolutionSegment('Use the road angle, then the width.'),
  ]),
  verification: SolutionSection(body: [
    TextSolutionSegment('Both routes give 160.'),
  ]),
);

/// Every screen here overflows a 690px viewport, so there is always somewhere
/// to scroll to and a retained offset would be visible.
const _tallBriefedDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Find the road slope', body: [
      TextSolutionSegment('The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. '),
    ]),
    SolutionStep(title: 'Scale the width', body: [
      TextSolutionSegment('The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. '),
    ]),
  ],
  finalAnswer: FinalAnswer(body: [
    TextSolutionSegment('The paved area is 160 square metres.'),
  ]),
  approach: SolutionSection(body: [
    TextSolutionSegment('The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. The road angle follows from the printed width. '),
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

  group('bookends', () {
    testWidgets('shows the briefing instead of the step card and the vault',
        (tester) async {
      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ))));
      await tester.pump();

      expect(find.byKey(const Key('solution_briefing')), findsOneWidget);
      expect(find.byType(SolutionStepOrganism), findsNothing);
      expect(find.byKey(const Key('vault_locked')), findsNothing);
      expect(find.text('Start solving'), findsOneWidget);
    });

    testWidgets('the briefing CTA advances rather than revealing',
        (tester) async {
      var next = 0;
      await tester.pumpWidget(_pump(_params(
        const SolutionReaderReady(
          document: _briefedDocument,
          onBriefing: true,
        ),
        onNext: () => next++,
      )));
      await tester.pump();

      await tester.tap(find.byKey(const Key('solution_cta')));
      await tester.pump();

      expect(next, 1);
    });

    testWidgets('returns to the step card once the briefing is passed',
        (tester) async {
      await tester.pumpWidget(
        _pump(_params(const SolutionReaderReady(document: _briefedDocument))),
      );
      await tester.pump();

      expect(find.byKey(const Key('solution_briefing')), findsNothing);
      expect(find.byType(SolutionStepOrganism), findsOneWidget);
    });

    testWidgets('puts the check below the vault once the answer is revealed',
        (tester) async {
      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _briefedDocument,
        stepIndex: 1,
        answerRevealed: true,
      ))));
      await tester.pump();

      expect(find.byKey(const Key('solution_check')), findsOneWidget);

      final vaultY =
          tester.getTopLeft(find.byKey(const Key('vault_revealed'))).dy;
      final checkY =
          tester.getTopLeft(find.byKey(const Key('solution_check'))).dy;
      expect(checkY, greaterThan(vaultY),
          reason: 'the check reads after the answer, not before it');
    });

    testWidgets('hides the check until the answer is revealed', (tester) async {
      await tester.pumpWidget(_pump(_params(
        const SolutionReaderReady(document: _briefedDocument, stepIndex: 1),
      )));
      await tester.pump();

      expect(find.byKey(const Key('solution_check')), findsNothing);
    });
  });

  group('a new screen starts at the top', () {
    /// The scroll view is reused across screens, so without an explicit reset
    /// its offset carries over and the student is dropped into the middle of
    /// the next screen with its heading scrolled off above them.
    Future<double> offset(WidgetTester tester) async {
      final position = tester
          .state<ScrollableState>(find
              .descendant(
                of: find.byKey(const Key('solution_scroll')),
                matching: find.byType(Scrollable),
              )
              .first)
          .position;
      return position.pixels;
    }

    testWidgets('resets when advancing off the briefing', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _tallBriefedDocument,
        onBriefing: true,
      ))));
      await tester.pumpAndSettle();

      await tester.drag(
          find.byKey(const Key('solution_scroll')), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(await offset(tester), greaterThan(0));

      await tester.pumpWidget(_pump(_params(
        const SolutionReaderReady(document: _tallBriefedDocument),
      )));
      await tester.pumpAndSettle();

      expect(await offset(tester), 0,
          reason: 'step one must open at its own heading');
    });

    testWidgets('resets when moving between steps', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_pump(
        _params(const SolutionReaderReady(document: _tallBriefedDocument)),
      ));
      await tester.pumpAndSettle();

      await tester.drag(
          find.byKey(const Key('solution_scroll')), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(await offset(tester), greaterThan(0));

      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _tallBriefedDocument,
        stepIndex: 1,
      ))));
      await tester.pumpAndSettle();

      expect(await offset(tester), 0);
    });

    testWidgets('holds its place when only the rationale toggles',
        (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_pump(_params(
        const SolutionReaderReady(document: _tallBriefedDocument),
      )));
      await tester.pumpAndSettle();

      await tester.drag(
          find.byKey(const Key('solution_scroll')), const Offset(0, -200));
      await tester.pumpAndSettle();
      final scrolled = await offset(tester);
      expect(scrolled, greaterThan(0));

      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _tallBriefedDocument,
        rationaleVisible: true,
      ))));
      await tester.pumpAndSettle();

      expect(await offset(tester), scrolled,
          reason: 'expanding a disclosure must not yank the reader to the top');
    });
  });
}
