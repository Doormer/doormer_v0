import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_share_line_params.dart';
import 'package:flutter/widgets.dart';

/// Plain holder — deliberately not Equatable, because it carries callbacks
/// which compare by reference.
class SolutionReaderParams {
  final SolutionReaderContent content;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onToggleRationale;
  final VoidCallback onRevealAnswer;

  /// Travels back to a trail position the student has already reached.
  final void Function(int position) onTravelTo;

  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  /// The line about sharing, above the buttons. Null on the sample.
  final SolutionShareLineParams? share;

  SolutionReaderParams({
    required this.content,
    required this.onNext,
    required this.onBack,
    required this.onToggleRationale,
    required this.onRevealAnswer,
    required this.onTravelTo,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
    this.share,
  });
}
