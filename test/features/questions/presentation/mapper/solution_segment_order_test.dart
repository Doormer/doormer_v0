import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:flutter_test/flutter_test.dart';

const _visual = VisualSolutionSegment(
  mediaType: 'image/png',
  url: 'https://example.test/step1.png',
  width: 1600,
  height: 1067,
  caption: 'caption',
  alt: 'alt',
);

void main() {
  test('hoists the visual to the front and keeps the rest in payload order', () {
    final ordered = diagramFirstOrder(const [
      TextSolutionSegment('Let theta be the angle.'),
      _visual,
      MathSolutionSegment(latex: r'\tan\theta=\frac{3}{4}', alt: 'tan'),
      TextSolutionSegment('So the slope is three quarters.'),
    ]);

    expect(ordered.map((o) => o.segment.runtimeType).toList(), [
      VisualSolutionSegment,
      TextSolutionSegment,
      MathSolutionSegment,
      TextSolutionSegment,
    ]);
  });

  test('preserves each segment original payload index for tap resolution', () {
    final ordered = diagramFirstOrder(const [
      TextSolutionSegment('first'),
      _visual,
      MathSolutionSegment(latex: 'x=1', alt: 'x'),
    ]);

    expect(ordered.map((o) => o.payloadIndex).toList(), [1, 0, 2]);
  });

  test('leaves a body with no visual untouched', () {
    final ordered = diagramFirstOrder(const [
      TextSolutionSegment('a'),
      TextSolutionSegment('b'),
    ]);

    expect(ordered.map((o) => o.payloadIndex).toList(), [0, 1]);
  });

  test('returns an empty list for an empty body', () {
    expect(diagramFirstOrder(const []), isEmpty);
  });
}
