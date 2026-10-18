import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/widgets.dart';

/// Shows one of [children] at a time, like an [IndexedStack], and cross-fades
/// when [index] changes: the child being left fades out while the new one
/// fades in, both at once.
///
/// Every child stays mounted, so each keeps its state. Outside a fade the
/// other children are offstage, as in an [IndexedStack]: not painted, not
/// tappable, not read by screen readers, and with their animations paused.
///
/// During a fade only the new child takes taps and is read by screen readers,
/// while the child being left keeps its animations running until it has faded
/// out. A change of [index] mid-fade carries each child on from where it is.
///
/// When motion is off the switch is instant.
class CrossFadeIndexedStackAtom extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 250);

  final int index;
  final List<Widget> children;

  const CrossFadeIndexedStackAtom({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<CrossFadeIndexedStackAtom> createState() =>
      _CrossFadeIndexedStackAtomState();
}

class _CrossFadeIndexedStackAtomState extends State<CrossFadeIndexedStackAtom> {
  /// The children fading out. They stay on stage until they have.
  final Set<int> _leaving = {};

  @override
  void didUpdateWidget(CrossFadeIndexedStackAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    _leaving.removeWhere((i) => i >= widget.children.length);
    if (widget.index == oldWidget.index) return;
    _leaving.remove(widget.index);
    if (MotionPolicy.of(context)) _leaving.add(oldWidget.index);
  }

  void _finishLeaving(int index) => setState(() => _leaving.remove(index));

  @override
  Widget build(BuildContext context) {
    final duration =
        MotionPolicy.duration(context, CrossFadeIndexedStackAtom.duration);
    return Stack(
      children: [
        for (var i = 0; i < widget.children.length; i++) _layer(i, duration),
      ],
    );
  }

  // Every child sits in the same wrappers whether shown or not, and only
  // their settings change, so no child is ever built afresh.
  Widget _layer(int i, Duration duration) {
    final shown = i == widget.index;
    final leaving = _leaving.contains(i);
    return Offstage(
      offstage: !shown && !leaving,
      child: TickerMode(
        enabled: shown || leaving,
        child: IgnorePointer(
          ignoring: !shown,
          child: ExcludeSemantics(
            excluding: !shown,
            child: AnimatedOpacity(
              opacity: shown ? 1 : 0,
              duration: duration,
              curve: Curves.easeInOut,
              onEnd: leaving ? () => _finishLeaving(i) : null,
              child: widget.children[i],
            ),
          ),
        ),
      ),
    );
  }
}
