import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:flutter/widgets.dart';

/// Plain holder — deliberately not Equatable, because it carries callbacks
/// which compare by reference.
class SolutionStepParams {
  final String levelLabel;
  final String stepTitle;
  final List<OrderedSegment> body;
  final List<OrderedSegment> rationale;
  final bool hasRationale;
  final bool rationaleVisible;
  final String rationaleToggleLabel;
  final VoidCallback onToggleRationale;
  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  SolutionStepParams({
    required this.levelLabel,
    required this.stepTitle,
    required this.body,
    required this.rationale,
    required this.hasRationale,
    required this.rationaleVisible,
    required this.rationaleToggleLabel,
    required this.onToggleRationale,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });
}
