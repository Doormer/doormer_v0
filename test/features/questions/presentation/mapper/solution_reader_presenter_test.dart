import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:flutter_test/flutter_test.dart';

const _visual = VisualSolutionSegment(
  mediaType: 'image/png',
  url: 'https://example.test/step1.png',
  width: 1600,
  height: 1067,
  caption: 'caption',
  alt: 'alt',
);

const _document = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(
      title: 'Find the road slope',
      body: [
        TextSolutionSegment('Let theta be the angle.'),
        _visual,
      ],
      rationale: [TextSolutionSegment('because')],
    ),
    SolutionStep(title: 'Scale the width', body: []),
    SolutionStep(title: 'Multiply out', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    MathSolutionSegment(latex: r'\boxed{160}', alt: '160'),
  ]),
);

const _briefedDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Find the road slope', body: []),
    SolutionStep(title: 'Scale the width', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    MathSolutionSegment(latex: r'\boxed{160}', alt: '160'),
  ]),
  approach: SolutionSection(body: [
    TextSolutionSegment('Use the road angle, then the width.'),
  ]),
  verification: SolutionSection(body: [
    TextSolutionSegment('Both routes give 160.'),
  ]),
);

/// One step plus a briefing: at stepIndex 0 the reader is on the briefing and
/// on the last step at the same time.
const _oneStepBriefedDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Only', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    MathSolutionSegment(latex: r'\boxed{160}', alt: '160'),
  ]),
  approach: SolutionSection(body: [
    TextSolutionSegment('One move is enough.'),
  ]),
);

void main() {
  test('labels the level with its total', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    );

    expect(
      content.levelLabel,
      'LEVEL 2 OF 3',
      reason: 'the index alone says where the student is but not how much is '
          'left; the total is what makes a last step feel like one',
    );
    expect(content.stepTitle, 'Scale the width');
  });

  test('orders the step body diagram-first', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _document),
    );

    expect(content.body.first.segment, isA<VisualSolutionSegment>());
    expect(content.body.first.payloadIndex, 1);
  });

  test('reports rationale availability and visibility', () {
    final withRationale = solutionReaderContent(
      const SolutionReaderReady(document: _document, rationaleVisible: true),
    );
    final withoutRationale = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    );

    expect(withRationale.hasRationale, isTrue);
    expect(withRationale.rationaleVisible, isTrue);
    expect(withRationale.rationaleToggleLabel, 'Why this works');
    expect(withoutRationale.hasRationale, isFalse);
  });

  test('builds the trail with done, current and upcoming nodes', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    );

    // Three steps plus the vault that closes the trail. This document has no
    // approach, so there is no briefing head.
    expect(content.trail.map((n) => n.state).toList(), const [
      SolutionTrailNodeState.done,
      SolutionTrailNodeState.current,
      SolutionTrailNodeState.upcoming,
      SolutionTrailNodeState.upcoming,
    ]);
    expect(content.trail[1].displayNumber, 2);
    expect(content.trail.first.semanticsLabel, 'Step 1: Find the road slope');
  });

  test('breaks a vault chain for every third of the working done', () {
    int chains(int stepIndex) => solutionReaderContent(
          SolutionReaderReady(document: _document, stepIndex: stepIndex),
        ).trail.last.chainsBroken!;

    // Three steps, so each step arrived at is a third of the road.
    expect(chains(0), 0, reason: 'nothing is loose before any work is done');
    expect(chains(1), 1);
    expect(chains(2), 3,
        reason: 'reaching the last step means the working is finished, so '
            'nothing is still holding the vault shut');
  });

  test('leaves the vault fully chained while the student reads the plan', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _briefedDocument, onBriefing: true),
    );

    expect(content.trail.last.chainsBroken, 0);
  });

  test('never chains the briefing marker', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _briefedDocument, onBriefing: true),
    );

    expect(content.trail.first.chainsBroken, isNull,
        reason: 'the briefing was never locked, so it was never chained');
  });

  test('closes the trail with the vault, amber only once it can be opened', () {
    final middle = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    );
    final atTheEnd = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 2),
    );
    final opened = solutionReaderContent(
      const SolutionReaderReady(
        document: _document,
        stepIndex: 2,
        answerRevealed: true,
      ),
    );

    expect(middle.trail.last.shape, SolutionTrailNodeShape.marker);
    expect(middle.trail.last.state, SolutionTrailNodeState.upcoming);
    expect(atTheEnd.trail.last.state, SolutionTrailNodeState.ready,
        reason: 'amber means openable, which is not the same as being here');
    expect(opened.trail.last.state, SolutionTrailNodeState.done);
    expect(
      atTheEnd.trail.where((n) => n.state == SolutionTrailNodeState.current),
      hasLength(1),
      reason: 'the student is only ever in one place',
    );
  });

  test('names the vault by how far away the answer is', () {
    expect(
      solutionReaderContent(const SolutionReaderReady(document: _document))
          .vaultLockedLabel,
      'Answer unlocks after step 3',
    );
    expect(
      solutionReaderContent(
        const SolutionReaderReady(document: _document, stepIndex: 2),
      ).vaultLockedLabel,
      'Tap to crack it open',
    );
  });

  test('changes the CTA at the end and offers the next question once revealed',
      () {
    final middle =
        solutionReaderContent(const SolutionReaderReady(document: _document));
    final last = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 2),
    );
    final revealed = solutionReaderContent(
      const SolutionReaderReady(
        document: _document,
        stepIndex: 2,
        answerRevealed: true,
      ),
    );

    expect(middle.ctaLabel, 'Next step');
    expect(middle.ctaEnabled, isTrue);
    expect(middle.canGoBack, isFalse);
    expect(last.ctaLabel, 'Reveal answer');
    expect(last.canGoBack, isTrue);
    expect(
      revealed.ctaLabel,
      'Ask another question',
      reason: 'a finished page is not a dead end; the button becomes the way '
          'onward rather than a label saying the student is done',
    );
    expect(revealed.ctaEnabled, isTrue);
    expect(revealed.answerBody.single.segment, isA<MathSolutionSegment>());
  });

  test('tells the student what they just did, counting properly', () {
    expect(
      solutionReaderContent(
        const SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
        ),
      ).vaultSolvedLabel,
      'You solved it in 3 steps',
    );

    const oneStep = SolutionDocument(
      schemaVersion: '3.0',
      steps: [SolutionStep(title: 'Only step', body: [])],
      finalAnswer: FinalAnswer(body: []),
    );
    expect(
      solutionReaderContent(
        const SolutionReaderReady(document: oneStep, answerRevealed: true),
      ).vaultSolvedLabel,
      'You solved it in 1 step',
      reason: 'a single step is not "1 steps"',
    );
  });

  test('counts the level the same way the trail does', () {
    // The kicker names the whole journey, as the approved design does, so it
    // must agree with the trail rather than tell a second, different story
    // about where the student is.
    for (var i = 0; i < _document.steps.length; i++) {
      final content = solutionReaderContent(
        SolutionReaderReady(document: _document, stepIndex: i),
      );
      final stepNodes = content.trail
          .where((n) => n.shape == SolutionTrailNodeShape.step)
          .toList();

      expect(content.levelLabel, 'LEVEL ${i + 1} OF ${stepNodes.length}');
      expect(
        stepNodes[i].state,
        SolutionTrailNodeState.current,
        reason: 'the kicker and the trail must point at the same step',
      );
    }
  });

  test(
      'gates answerRevealed to isLastStep — reveal-then-back does not leak on earlier steps',
      () {
    // answerRevealed=true persists in state after reveal, but on a non-last
    // step the presenter must hide it so the vault stays locked and the CTA
    // stays enabled.
    final content = solutionReaderContent(
      const SolutionReaderReady(
        document: _document,
        stepIndex: 0, // not the last step
        answerRevealed: true,
      ),
    );

    expect(content.answerRevealed, isFalse,
        reason: 'vault must not be revealed on a non-last step');
    expect(content.ctaEnabled, isTrue,
        reason: 'CTA must remain enabled on a non-last step');
    expect(content.ctaLabel, 'Next step');
  });

  group('briefing', () {
    test('hands the approach body and the note to the briefing screen', () {
      final content = solutionReaderContent(const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
        note: 'The width is derived.',
      ));

      expect(content.onBriefing, isTrue);
      expect(content.briefingTitle, 'The plan');
      expect(
        (content.briefingBody.single.segment as TextSolutionSegment).value,
        'Use the road angle, then the width.',
      );
      expect(content.note, 'The width is derived.');
    });

    test('calls the briefing CTA Start solving and disables going back', () {
      final content = solutionReaderContent(const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ));

      expect(content.ctaLabel, 'Start solving');
      expect(content.ctaEnabled, isTrue);
      expect(content.canGoBack, isFalse);
    });

    test('lets step one go back to the briefing', () {
      final withBriefing = solutionReaderContent(
          const SolutionReaderReady(document: _briefedDocument));
      final withoutBriefing =
          solutionReaderContent(const SolutionReaderReady(document: _document));

      expect(withBriefing.canGoBack, isTrue);
      expect(withoutBriefing.canGoBack, isFalse);
    });

    test('heads the trail with a flagged node and keeps step numbering', () {
      final content = solutionReaderContent(const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ));

      expect(content.trail, hasLength(4));
      expect(content.trail.first.icon, isNotNull);
      expect(content.trail.first.state, SolutionTrailNodeState.current);
      expect(content.trail.first.semanticsLabel, 'The plan');
      expect(content.trail[1].displayNumber, 1,
          reason: 'the briefing must not shift step numbering');
      expect(content.trail[1].state, SolutionTrailNodeState.upcoming);
    });

    test('marks the briefing done once the student is on a step', () {
      final content = solutionReaderContent(
          const SolutionReaderReady(document: _briefedDocument));

      expect(content.trail.first.state, SolutionTrailNodeState.done);
      expect(content.trail[1].state, SolutionTrailNodeState.current);
    });

    test('omits the trail head entirely when there is no approach', () {
      final content =
          solutionReaderContent(const SolutionReaderReady(document: _document));

      expect(content.trail, hasLength(4));
      expect(
        content.trail.take(3).every((n) => n.icon == null),
        isTrue,
        reason: 'only the vault closes the trail; nothing heads it',
      );
      expect(content.onBriefing, isFalse);
    });

    test('does not report the last step while the briefing is showing', () {
      final content = solutionReaderContent(const SolutionReaderReady(
        document: _oneStepBriefedDocument,
        onBriefing: true,
      ));

      expect(content.isLastStep, isFalse,
          reason:
              'the CTA would otherwise reveal the answer from the briefing');
      expect(content.ctaLabel, 'Start solving');
      expect(content.answerRevealed, isFalse);
    });
  });

  group('check', () {
    test('withholds the verification until the answer is revealed', () {
      final beforeReveal = solutionReaderContent(
        const SolutionReaderReady(document: _briefedDocument, stepIndex: 1),
      );

      expect(beforeReveal.checkBody, isEmpty,
          reason: 'a check read before the answer is just another step');
    });

    test('releases the verification with the answer', () {
      final revealed = solutionReaderContent(const SolutionReaderReady(
        document: _briefedDocument,
        stepIndex: 1,
        answerRevealed: true,
      ));

      expect(revealed.checkTitle, 'Check it');
      expect(
        (revealed.checkBody.single.segment as TextSolutionSegment).value,
        'Both routes give 160.',
      );
    });

    test('stays empty when the document carries no verification', () {
      final revealed = solutionReaderContent(const SolutionReaderReady(
        document: _document,
        stepIndex: 2,
        answerRevealed: true,
      ));

      expect(revealed.checkBody, isEmpty);
    });
  });

  group('standing', () {
    const profile = QuestProfile(
      bankedXp: 120,
      streakDays: 3,
      topic: 'Geometry - Area',
      questionTitle: 'Road through a field',
    );

    test('banks XP for the steps already read, not for the one in hand', () {
      // 3 steps, so step values are 10, 15, 20. Arriving at step 2 means one
      // step is read; arriving at step 3 means two are.
      final opening = solutionReaderContent(
        const SolutionReaderReady(document: _document, profile: profile),
      );
      final second = solutionReaderContent(
        const SolutionReaderReady(
          document: _document,
          stepIndex: 1,
          profile: profile,
        ),
      );
      final third = solutionReaderContent(
        const SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          profile: profile,
        ),
      );

      expect(opening.xpLabel, '120 XP');
      expect(second.xpLabel, '130 XP');
      expect(third.xpLabel, '145 XP');
    });

    test('prices the first step cheap and the last step dear', () {
      expect(stepXpValue(0, 3), 10);
      expect(stepXpValue(1, 3), 15);
      expect(stepXpValue(2, 3), 20);
    });

    test('shows what the step in hand is worth, but not on the briefing', () {
      final onStep = solutionReaderContent(
        const SolutionReaderReady(
          document: _document,
          stepIndex: 1,
          profile: profile,
        ),
      );
      final onBriefing = solutionReaderContent(
        const SolutionReaderReady(
          document: _briefedDocument,
          onBriefing: true,
          profile: profile,
        ),
      );

      expect(onStep.stepXpLabel, '+15 XP');
      expect(onBriefing.stepXpLabel, '',
          reason: 'you are not paid for arriving');
    });

    test('leaves the standing copy empty until the standing loads', () {
      final content = solutionReaderContent(
        const SolutionReaderReady(document: _document),
      );

      expect(content.xpLabel, '');
      expect(content.streakLabel, '');
      expect(content.topic, '');
      expect(content.questionTitle, '');
    });

    test('names the streak in days', () {
      final content = solutionReaderContent(
        const SolutionReaderReady(document: _document, profile: profile),
      );

      expect(content.streakLabel, '3-day');
      expect(content.topic, 'Geometry - Area');
      expect(content.questionTitle, 'Road through a field');
    });
  });
}
