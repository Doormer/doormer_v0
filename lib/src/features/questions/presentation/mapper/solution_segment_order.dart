import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';

/// A segment paired with the index it occupied in the payload.
///
/// Rendering reorders segments; tap-to-enlarge must still resolve the segment
/// the student actually tapped, so the original index travels with it.
class OrderedSegment {
  final SolutionSegment segment;
  final int payloadIndex;

  const OrderedSegment({
    required this.segment,
    required this.payloadIndex,
  });
}

/// Hoists visual segments to the front, leaving every other segment in payload
/// order.
///
/// The payload orders each step prose -> visual -> math, which pushes the
/// diagram below the fold; the student then reads about a figure they cannot
/// see. Leading with the picture frames the words instead of trailing them.
List<OrderedSegment> diagramFirstOrder(List<SolutionSegment> body) {
  final indexed = <OrderedSegment>[
    for (var i = 0; i < body.length; i++)
      OrderedSegment(segment: body[i], payloadIndex: i),
  ];

  return <OrderedSegment>[
    ...indexed.where((o) => o.segment is VisualSolutionSegment),
    ...indexed.where((o) => o.segment is! VisualSolutionSegment),
  ];
}
