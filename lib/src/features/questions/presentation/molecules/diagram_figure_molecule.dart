import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Diagram plus caption. A remote image can 403 — the payload's URLs are
/// SAS-signed and expire — so on failure the figure and its caption disappear
/// together rather than leaving a broken glyph and an orphan caption.
class DiagramFigureMolecule extends StatefulWidget {
  /// Most of the viewport an inline figure may claim.
  ///
  /// [AspectRatio] derives height from the width it is offered, so a wider
  /// window makes a *taller* figure: uncapped, the diagram grew to 507px in a
  /// 900px laptop window and pushed the working that explains it off screen.
  /// The cap keeps the figure and some of its reasoning visible together.
  ///
  /// It lives here rather than on [DiagramAtom] because the enlarge view uses
  /// the same atom and wants the opposite -- as much of the screen as the
  /// figure can take. Phones are unaffected either way: at 358px of column a
  /// figure is 239px tall, well under the cap, so width still decides.
  static const double maxViewportFraction = 0.34;

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

  @override
  void didUpdateWidget(covariant DiagramFigureMolecule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visual.url != widget.visual.url) {
      setState(() => _failed = false);
    }
  }

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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height *
                      DiagramFigureMolecule.maxViewportFraction,
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
