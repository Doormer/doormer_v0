import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/material.dart';

/// Lifts one piece of a card into place, a beat behind the piece above it.
///
/// A screen that swaps its whole contents at once gives the eye nothing to
/// follow. Staggering the arrival — kicker, then heading, then body — says in
/// what order to read, without any copy having to say it.
///
/// [order] is the child's position in the stagger, from zero.
///
/// When motion is off this renders the child plainly: the content is the
/// point, the movement is not. It must never be left stuck at its start value.
class RiseInAtom extends StatefulWidget {
  static const Duration _travel = Duration(milliseconds: 480);
  static const Duration _step = Duration(milliseconds: 80);
  static const Duration _lead = Duration(milliseconds: 40);

  /// How far below its resting place a piece starts.
  static const double _lift = 12;

  final int order;
  final Widget child;

  const RiseInAtom({super.key, required this.order, required this.child});

  @override
  State<RiseInAtom> createState() => _RiseInAtomState();
}

class _RiseInAtomState extends State<RiseInAtom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rise;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Built even when motion is off, so dispose never reaches back into a
    // deactivated element for a ticker it is about to throw away.
    _controller = AnimationController(
      vsync: this,
      duration: RiseInAtom._travel + RiseInAtom._step * widget.order,
    );

    final total = _controller.duration!.inMicroseconds;
    final delay =
        (RiseInAtom._lead + RiseInAtom._step * widget.order).inMicroseconds;
    _rise = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (delay / total).clamp(0.0, 0.9),
        1,
        curve: const Cubic(.22, 1, .36, 1),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !MotionPolicy.of(context)) return;
    _started = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MotionPolicy.of(context)) return widget.child;

    return AnimatedBuilder(
      animation: _rise,
      builder: (context, child) {
        final t = _rise.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, RiseInAtom._lift * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
