import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/presentation/atoms/solution_text_atom.dart';
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

Widget _pump(SolutionReaderParams params, {bool motion = true}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !motion),
        child: SolutionReaderTemplate(params: params),
      ),
    ),
  );
}

/// A three-step run with a standing already banked, so every move pays a
/// different amount and the counter has somewhere to climb from.
const _paidDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Find the road slope', body: []),
    SolutionStep(title: 'Scale the width', body: []),
    SolutionStep(title: 'Multiply out', body: []),
  ],
  finalAnswer: FinalAnswer(body: [TextSolutionSegment('160')]),
);

const _profile = QuestProfile(
  bankedXp: 120,
  streakDays: 4,
  topic: 'Geometry - Area',
  questionTitle: 'Road through a field',
);

SolutionReaderReady _atStep(int index) => SolutionReaderReady(
      document: _paidDocument,
      stepIndex: index,
      profile: _profile,
    );

SolutionReaderParams _params(
  SolutionReaderReady state, {
  VoidCallback? onNext,
  VoidCallback? onBack,
  VoidCallback? onRevealAnswer,
}) {
  return SolutionReaderParams(
    content: solutionReaderContent(state),
    onNext: onNext ?? () {},
    onBack: onBack ?? () {},
    onToggleRationale: () {},
    onRevealAnswer: onRevealAnswer ?? () {},
    onTravelTo: (_) {},
    onEnlargeVisual: (_) {},
  );
}

void main() {
  _xpFlightTests();
  _revealResistTests();
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

      expect(
        find.descendant(
          of: find.byKey(const Key('vault_revealed')),
          matching: find.byKey(const Key('solution_check')),
        ),
        findsOneWidget,
        reason: 'the working is part of the payoff, not a card after it',
      );

      final answerY = tester.getTopLeft(find.byType(SolutionTextAtom).last).dy;
      final checkY =
          tester.getTopLeft(find.byKey(const Key('solution_check'))).dy;
      expect(checkY, greaterThan(answerY),
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

  group('the escaping XP sticker', () {
    testWidgets('is not clipped by the top of the scroll view',
        (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _pump(_params(const SolutionReaderReady(document: _document))),
      );
      await tester.pumpAndSettle();

      final sticker = find.byKey(const Key('step_xp_sticker'));
      expect(sticker, findsOneWidget);

      final stickerTop = tester.getTopLeft(sticker).dy;
      final scrollTop =
          tester.getTopLeft(find.byKey(const Key('solution_scroll'))).dy;

      expect(
        stickerTop,
        greaterThanOrEqualTo(scrollTop),
        reason: 'the sticker sits above the card, so the scroll view must '
            'reserve headroom for it or the viewport cuts the tag in half',
      );
    });
  });

  group('revealing the answer', () {
    testWidgets('brings the vault into view', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _tallBriefedDocument,
        stepIndex: 1,
      ))));
      await tester.pumpAndSettle();

      final scrollRect =
          tester.getRect(find.byKey(const Key('solution_scroll')));

      expect(
        tester.getTopLeft(find.byKey(const Key('vault_locked'))).dy,
        greaterThan(scrollRect.bottom),
        reason: 'the vault starts below the fold, which is what makes the '
            'reveal invisible without this behaviour',
      );

      await tester.pumpWidget(_pump(_params(const SolutionReaderReady(
        document: _tallBriefedDocument,
        stepIndex: 1,
        answerRevealed: true,
      ))));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byKey(const Key('vault_revealed'))).dy,
        lessThan(scrollRect.bottom),
        reason: 'the answer is the payoff of the page and must not stay off '
            'screen when the student asks for it',
      );
    });
  });
}

void _xpFlightTests() {
  group('XP flight', () {
    testWidgets('holds the counter until the reward actually arrives',
        (tester) async {
      await tester.pumpWidget(_pump(_params(_atStep(0))));
      await tester.pumpAndSettle();
      expect(find.text('120 XP'), findsOneWidget);

      await tester.pumpWidget(_pump(_params(_atStep(1))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('xp_pellet')), findsOneWidget);
      expect(find.text('120 XP'), findsOneWidget,
          reason: 'a counter that pays before the pellet lands makes the '
              'flight a lie');

      await tester.pumpAndSettle();
      expect(find.text('130 XP'), findsOneWidget);
      expect(find.byKey(const Key('xp_pellet')), findsNothing);
    });

    testWidgets('the pellet carries what was banked, not the next reward',
        (tester) async {
      await tester.pumpWidget(_pump(_params(_atStep(0))));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_params(_atStep(1))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('+15 XP'), findsOneWidget,
          reason: 'the sticker advertises the step now on screen');
      expect(
        find.descendant(
          of: find.byKey(const Key('xp_pellet')),
          matching: find.text('+10 XP'),
        ),
        findsOneWidget,
        reason: 'reading the sticker would pay a pellet of 15 while the '
            'counter climbed 10',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('lands the number with no pellet under reduced motion',
        (tester) async {
      await tester.pumpWidget(_pump(_params(_atStep(0)), motion: false));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_params(_atStep(1)), motion: false));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('xp_pellet')), findsNothing);
      expect(find.text('130 XP'), findsOneWidget,
          reason: 'the pellet is decoration; the total is not');
    });

    testWidgets('banks the first award when a second overtakes it',
        (tester) async {
      await tester.pumpWidget(_pump(_params(_atStep(0))));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_pump(_params(_atStep(1))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('120 XP'), findsOneWidget);

      await tester.pumpWidget(_pump(_params(_atStep(2))));
      await tester.pump();
      await tester.pump();

      expect(find.text('130 XP'), findsOneWidget,
          reason: 'skipping ahead may cost the animation, never the XP');

      await tester.pumpAndSettle();
      expect(find.text('145 XP'), findsOneWidget);
    });

    testWidgets('travelling back never pays again', (tester) async {
      await tester.pumpWidget(_pump(_params(_atStep(2))));
      await tester.pumpAndSettle();
      expect(find.text('145 XP'), findsOneWidget);

      await tester.pumpWidget(_pump(_params(_atStep(0))));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('xp_pellet')), findsNothing);
      expect(find.text('120 XP'), findsOneWidget,
          reason: 'the total is derived from where the student is, so going '
              'back gives it back');
    });
  });
}

void _revealResistTests() {
  group('revealing the answer', () {
    testWidgets('holds the whole page shut while the lock refuses',
        (tester) async {
      var revealed = 0;
      await tester.pumpWidget(_pump(
        _params(_atStep(2), onRevealAnswer: () => revealed++),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('solution_cta')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(revealed, 0,
          reason: 'the answer must not be handed over on the press; the page '
              'turns over on one beat, after the lock gives');
      expect(find.byKey(const Key('vault_locked')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(revealed, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('rattles the vault during the refusal', (tester) async {
      await tester.pumpWidget(_pump(_params(_atStep(2))));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('solution_cta')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      final shifted = tester
          .widgetList<Transform>(find.ancestor(
            of: find.byKey(const Key('vault_locked')),
            matching: find.byType(Transform),
          ))
          .fold<double>(0, (acc, t) => acc + t.transform.getTranslation().x);
      expect(shifted.abs(), greaterThan(1));
      await tester.pumpAndSettle();
    });

    testWidgets('reveals immediately under reduced motion', (tester) async {
      var revealed = 0;
      await tester.pumpWidget(_pump(
        _params(_atStep(2), onRevealAnswer: () => revealed++),
        motion: false,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('solution_cta')));
      await tester.pump();

      expect(revealed, 1,
          reason: 'the answer is not allowed to wait on an animation that '
              'never runs');
    });

    testWidgets('a second press during the refusal does not reveal twice',
        (tester) async {
      var revealed = 0;
      await tester.pumpWidget(_pump(
        _params(_atStep(2), onRevealAnswer: () => revealed++),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('solution_cta')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('solution_cta')));
      await tester.pump(const Duration(milliseconds: 600));

      expect(revealed, 1);
      await tester.pumpAndSettle();
    });
  });
}
