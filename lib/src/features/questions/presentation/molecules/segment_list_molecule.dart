import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/math_block_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/solution_text_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/diagram_figure_molecule.dart';
import 'package:flutter/material.dart';

/// Renders an already-ordered segment list. Ordering is decided above this
/// widget so the molecule stays dumb.
class SegmentListMolecule extends StatelessWidget {
  final List<OrderedSegment> segments;
  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const SegmentListMolecule({
    super.key,
    required this.segments,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ordered in segments)
          _buildSegment(ordered.segment, ordered.payloadIndex),
      ],
    );
  }

  Widget _buildSegment(SolutionSegment segment, int payloadIndex) {
    final key = ValueKey<int>(payloadIndex);

    if (segment is TextSolutionSegment) {
      return SolutionTextAtom(key: key, value: segment.value);
    }
    if (segment is MathSolutionSegment) {
      return MathBlockAtom(
        key: key,
        latex: segment.latex,
        semanticsLabel: segment.alt,
      );
    }
    if (segment is VisualSolutionSegment) {
      return DiagramFigureMolecule(
        key: key,
        visual: segment,
        onEnlarge: () => onEnlargeVisual(segment),
        imageProviderBuilder: imageProviderBuilder,
      );
    }
    return const SizedBox.shrink();
  }
}
