import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';

/// Plain holder — deliberately not Equatable, because it carries callbacks
/// which compare by reference.
class SolutionBriefingParams {
  final String title;
  final List<OrderedSegment> body;

  /// Empty when the solver sent no caveat.
  final String note;

  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  SolutionBriefingParams({
    required this.title,
    required this.body,
    required this.note,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });
}
