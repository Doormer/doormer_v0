import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisualSolutionSegment', () {
    test('exposes payload geometry as an aspect ratio', () {
      const visual = VisualSolutionSegment(
        mediaType: 'image/png',
        url: 'https://example.test/diagram.png',
        width: 1600,
        height: 1067,
        caption: 'The 5 m and 4 m measurements determine the road angle.',
        alt: 'A right triangle formed by the 5 m vertical separation.',
      );

      expect(visual, isA<SolutionSegment>());
      expect(visual.aspectRatio, closeTo(1.4995, 0.001));
    });

    test('falls back to 1.5 when height is zero', () {
      const visual = VisualSolutionSegment(
        mediaType: 'image/png',
        url: 'https://example.test/diagram.png',
        width: 1600,
        height: 0,
        caption: '',
        alt: '',
      );

      expect(visual.aspectRatio, 1.5);
    });
  });

  group('schema 3.0 additions', () {
    test('step rationale defaults to empty and accepts segments', () {
      const bare = SolutionStep(title: 'Find the slope', body: []);
      expect(bare.rationale, isEmpty);

      const withRationale = SolutionStep(
        title: 'Find the slope',
        body: [],
        rationale: [TextSolutionSegment('The 5 m segment is the hypotenuse.')],
      );
      expect(withRationale.rationale.single, isA<TextSolutionSegment>());
    });

    test('document approach and verification default to empty sections', () {
      const document = SolutionDocument(
        schemaVersion: '3.0',
        steps: [],
        finalAnswer: FinalAnswer(body: []),
      );

      expect(document.approach.body, isEmpty);
      expect(document.verification.body, isEmpty);
    });

    test('outcome note defaults to an empty string', () {
      const outcome = PhotoQuestionSolveOutcome(
        status: PhotoQuestionSolveStatus.solved,
        questionId: '57',
        solution: null,
      );

      expect(outcome.note, '');
    });
  });
}
