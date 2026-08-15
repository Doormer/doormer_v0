import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Diagram plus caption. A remote image can 403 — the payload's URLs are
/// SAS-signed and expire — so on failure the figure and its caption disappear
/// together rather than leaving a broken glyph and an orphan caption.
class DiagramFigureMolecule extends StatefulWidget {
  final VisualSolutionSegment visual;
  final VoidCallback onEnlarge;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const DiagramFigureMolecule({
    super.key,
    required this.visual,
    required this.onEnlarge,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  State<DiagramFigureMolecule> createState() => _DiagramFigureMoleculeState();
}

class _DiagramFigureMoleculeState extends State<DiagramFigureMolecule> {
  bool _failed = false;

  void _onFailed() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox.shrink();
    }

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: const Key('diagram_figure'),
          onTap: widget.onEnlarge,
          child: Container(
            key: const Key('diagram_image'),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: DiagramAtom(
              url: widget.visual.url,
              aspectRatio: widget.visual.aspectRatio,
              semanticsLabel: widget.visual.alt,
              onFailed: _onFailed,
              imageProviderBuilder: widget.imageProviderBuilder,
            ),
          ),
        ),
        if (widget.visual.caption.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            widget.visual.caption,
            key: const Key('diagram_caption'),
            style: tt.bodySmall?.copyWith(
              fontSize: 12.sp,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
