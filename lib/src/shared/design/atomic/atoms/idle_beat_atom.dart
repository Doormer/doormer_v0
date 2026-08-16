import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/widgets.dart';

/// Runs an idle animation for a fixed number of beats and then stops.
///
/// Idle motion earns attention by being unusual. A flame that bobs forever
/// stops being a flame that bobs and becomes part of the furniture, and the
/// student's eye edits it out — so the loop costs battery and delivers
/// nothing. A few beats on arrival says "look here" and then gets out of the
/// way.
///
/// Bounding the loop is also what keeps the widget testable. An endless
/// animation makes `pumpAndSettle` hang in every test that renders this
/// subtree, however far away, so one infinite loop can quietly make a whole
/// screen untestable.
class IdleBeatAtom extends StatefulWidget {
  /// One full there-and-back cycle.
  final Duration period;

  /// How many cycles to run before settling. Must be at least one.
  final int beats;

  /// Held still for this long first, so a beat that accompanies something
  /// arriving does not compete with the arrival itself.
  final Duration delay;

  /// Called with the phase of the current beat, 0 to 1, and 0 once at rest.
  final Widget Function(BuildContext context, double phase, Widget? child)
      builder;

  final Widget? child;

  const IdleBeatAtom({
    super.key,
    required this.period,
    required this.builder,
    this.beats = 3,
    this.delay = Duration.zero,
    this.child,
  }) : assert(beats > 0, 'an idle beat that never beats is just a widget');

  @override
  State<IdleBeatAtom> createState() => _IdleBeatAtomState();
}

class _IdleBeatAtomState extends State<IdleBeatAtom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// The delay is part of the run rather than a `Timer`, so there is nothing
  /// left to cancel if this is disposed mid-beat.
  late final double _delayFraction;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.period * widget.beats;
    _delayFraction = total.inMicroseconds == 0
        ? 0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _controller = AnimationController(vsync: this, duration: total);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MotionPolicy.of(context)) _controller.forward();
    });
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
        final phase = v <= _delayFraction || v >= 1
            ? 0.0
            : (((v - _delayFraction) / (1 - _delayFraction)) * widget.beats) %
                1;
        return widget.builder(context, phase, child);
      },
      child: widget.child,
    );
  }
}
