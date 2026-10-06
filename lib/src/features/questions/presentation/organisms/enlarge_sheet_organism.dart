import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/atoms/quest_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The frame an enlarged picture sits in: an opaque backdrop, a close button,
/// and room to scroll. An enlarged diagram and an enlarged photo share it.
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
class EnlargeSheetOrganism extends StatefulWidget {
  static const Duration backdropFade = Duration(milliseconds: 220);
  static const Duration cardRise = Duration(milliseconds: 280);

  final VoidCallback onClose;
  final Widget child;

  const EnlargeSheetOrganism({
    super.key,
    required this.onClose,
    required this.child,
  });

  @override
  State<EnlargeSheetOrganism> createState() => _EnlargeSheetOrganismState();
}

class _EnlargeSheetOrganismState extends State<EnlargeSheetOrganism>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: EnlargeSheetOrganism.cardRise,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // With motion off the sheet is simply already here: it must never be
      // left held at zero opacity, which would hide the picture outright.
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
    final cs = context.colorScheme;

    // The backdrop closes over the page faster than the picture arrives, so
    // the page is gone before the picture lands on top of where it was.
    final fadeFraction = EnlargeSheetOrganism.backdropFade.inMilliseconds /
        EnlargeSheetOrganism.cardRise.inMilliseconds;
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
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    color: cs.onSurface,
                    tooltip: 'Close',
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: widget.child,
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
