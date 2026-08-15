import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A diagram at full width, over an opaque backdrop.
///
/// A translucent backdrop left the step heading and body readable behind the
/// figure, with the road line running through the text. Contrast scoring
/// called that 1.10:1 -- "invisible" -- but a 3x crop showed it plainly
/// legible, so the sheet is opaque. The gradient keeps it from being a flat
/// black hole.
class DiagramEnlargeOrganism extends StatelessWidget {
  static const Color _backdropInner = Color(0xFF16103A);
  static const Color _backdropOuter = Color(0xFF07040F);

  final VisualSolutionSegment visual;
  final VoidCallback onClose;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const DiagramEnlargeOrganism({
    super.key,
    required this.visual,
    required this.onClose,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return DecoratedBox(
      key: const Key('enlarge_backdrop'),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1),
          radius: 1.2,
          colors: [_backdropInner, _backdropOuter],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const Key('enlarge_close'),
                onPressed: onClose,
                icon: const Icon(Icons.close),
                color: cs.onSurface,
                tooltip: 'Close',
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiagramAtom(
                        url: visual.url,
                        aspectRatio: visual.aspectRatio,
                        semanticsLabel: visual.alt,
                        onFailed: onClose,
                        imageProviderBuilder: imageProviderBuilder,
                      ),
                      if (visual.caption.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Text(
                          visual.caption,
                          style: tt.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
