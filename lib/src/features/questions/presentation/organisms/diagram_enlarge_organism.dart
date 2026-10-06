import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/organisms/enlarge_sheet_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A diagram at full width, with its caption, in the enlarge sheet. A diagram
/// that will not load closes the sheet, as it always has.
class DiagramEnlargeOrganism extends StatelessWidget {
  static const Duration backdropFade = EnlargeSheetOrganism.backdropFade;
  static const Duration cardRise = EnlargeSheetOrganism.cardRise;

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

    return EnlargeSheetOrganism(
      onClose: onClose,
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
    );
  }
}
