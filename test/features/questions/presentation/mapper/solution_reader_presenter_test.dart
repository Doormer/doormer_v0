import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
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
  test('labels the level without a total', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    );

    expect(content.levelLabel, 'LEVEL 2');
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

    expect(content.trail.map((n) => n.state).toList(), const [
      SolutionTrailNodeState.done,
      SolutionTrailNodeState.current,
      SolutionTrailNodeState.upcoming,
    ]);
    expect(content.trail[1].displayNumber, 2);
    expect(content.trail.first.semanticsLabel, 'Step 1: Find the road slope');
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

  test('changes the CTA at the end and retires it once revealed', () {
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
    expect(revealed.ctaLabel, 'Solved');
    expect(revealed.ctaEnabled, isFalse);
    expect(revealed.answerBody.single.segment, isA<MathSolutionSegment>());
  });

  test('never emits a step-of-total string', () {
    final content = solutionReaderContent(
      const SolutionReaderReady(document: _document, stepIndex: 1),
    );

    final copy = [
      content.levelLabel,
      content.stepTitle,
      content.ctaLabel,
      content.rationaleToggleLabel,
    ];
    for (final line in copy) {
      expect(line.contains(' of '), isFalse,
          reason: 'the trail is the only progress indicator');
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
      final withBriefing =
          solutionReaderContent(const SolutionReaderReady(document: _briefedDocument));
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

      expect(content.trail, hasLength(3));
      expect(content.trail.first.icon, isNotNull);
      expect(content.trail.first.state, SolutionTrailNodeState.current);
      expect(content.trail.first.semanticsLabel, 'The plan');
      expect(content.trail[1].displayNumber, 1,
          reason: 'the briefing must not shift step numbering');
      expect(content.trail[1].state, SolutionTrailNodeState.upcoming);
    });

    test('marks the briefing done once the student is on a step', () {
      final content =
          solutionReaderContent(const SolutionReaderReady(document: _briefedDocument));

      expect(content.trail.first.state, SolutionTrailNodeState.done);
      expect(content.trail[1].state, SolutionTrailNodeState.current);
    });

    test('omits the trail head entirely when there is no approach', () {
      final content =
          solutionReaderContent(const SolutionReaderReady(document: _document));

      expect(content.trail, hasLength(3));
      expect(content.trail.every((n) => n.icon == null), isTrue);
      expect(content.onBriefing, isFalse);
    });

    test('does not report the last step while the briefing is showing', () {
      final content = solutionReaderContent(const SolutionReaderReady(
        document: _oneStepBriefedDocument,
        onBriefing: true,
      ));

      expect(content.isLastStep, isFalse,
          reason: 'the CTA would otherwise reveal the answer from the briefing');
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
}
