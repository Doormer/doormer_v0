import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/material.dart';

/// Punches its child whenever [trigger] changes.
///
/// A number that changes silently is easy to miss, and the point of banking XP
/// is that the student notices it. The punch is what turns a new value into an
/// event. It never fires on first build: arriving at a page is not an event.
class PunchAtom extends StatefulWidget {
  static const Duration _punch = Duration(milliseconds: 620);

  final Object? trigger;
  final Widget child;

  const PunchAtom({super.key, required this.trigger, required this.child});

  @override
  State<PunchAtom> createState() => _PunchAtomState();
}

class _PunchAtomState extends State<PunchAtom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: PunchAtom._punch);
  }

  @override
  void didUpdateWidget(PunchAtom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger == widget.trigger) return;
    if (!MotionPolicy.of(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        if (v == 0 || v == 1) return child!;
        // Out hard, back gently: the swell reads as the number being struck
        // rather than as it drifting to a new size.
        final t = v < 0.3
            ? const Cubic(.2, 1.7, .4, 1).transform(v / 0.3)
            : 1 - (v - 0.3) / 0.7;
        return Transform.scale(scale: 1 + 0.22 * t, child: child);
      },
      child: widget.child,
    );
  }
}
