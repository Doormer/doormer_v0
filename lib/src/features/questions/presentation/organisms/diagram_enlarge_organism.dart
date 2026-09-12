import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/quest_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A diagram at full width, over an opaque backdrop.
///
/// It paints the app's own [QuestBackdrop] rather than a backdrop of its own.
/// The route is clipped to the content column, so a bespoke one showed as a
/// slab with two hard vertical edges and the real page still visible either
/// side of it on a wide window. Painting the same thing as the surround makes
/// the sheet seamless while staying every bit as opaque.
///
/// A translucent backdrop left the step heading and body readable behind the
/// figure, with the road line running through the text. Contrast scoring
/// called that 1.10:1 -- "invisible" -- but a 3x crop showed it plainly
/// legible, so the sheet is opaque. The gradient keeps it from being a flat
/// black hole.
class DiagramEnlargeOrganism extends StatefulWidget {
  static const Duration backdropFade = Duration(milliseconds: 220);
  static const Duration cardRise = Duration(milliseconds: 280);

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
  State<DiagramEnlargeOrganism> createState() => _DiagramEnlargeOrganismState();
}

class _DiagramEnlargeOrganismState extends State<DiagramEnlargeOrganism>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: DiagramEnlargeOrganism.cardRise,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // With motion off the sheet is simply already here: it must never be
      // left held at zero opacity, which would hide the figure outright.
      if (MotionPolicy.of(context)) {
        _entrance.forward();
      } else {
        _entrance.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = widget.visual;
    final onClose = widget.onClose;
    final imageProviderBuilder = widget.imageProviderBuilder;
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // The backdrop closes over the page faster than the figure arrives, so the
    // step text is gone before the diagram lands on top of where it was.
    final fadeFraction = DiagramEnlargeOrganism.backdropFade.inMilliseconds /
        DiagramEnlargeOrganism.cardRise.inMilliseconds;
    final backdrop = CurvedAnimation(
      parent: _entrance,
      curve: Interval(0, fadeFraction, curve: Curves.easeOut),
    );
    final rise = CurvedAnimation(
      parent: _entrance,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: backdrop,
          child: const QuestBackdrop(
            key: Key('enlarge_backdrop'),
            child: SizedBox.expand(),
          ),
        ),
        SlideTransition(
          key: const Key('enlarge_card'),
          position: Tween<Offset>(
            begin: const Offset(0, 0.14),
            end: Offset.zero,
          ).animate(rise),
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
        ),
      ],
    );
  }
}
