import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:flutter/material.dart';

/// Snaps a card into being when its contents are replaced.
///
/// Advancing a step changes every word on the card but not its frame, so
/// without this the page can look like nothing happened. The overshoot is what
/// makes it read as a new card arriving rather than text being edited in
/// place.
///
/// Rebuild this under a key that changes with the content, otherwise the same
/// state is reused and the pop never replays.
class CardPopAtom extends StatefulWidget {
  static const Duration _pop = Duration(milliseconds: 480);

  final Widget child;

  const CardPopAtom({super.key, required this.child});

  @override
  State<CardPopAtom> createState() => _CardPopAtomState();
}

class _CardPopAtomState extends State<CardPopAtom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: CardPopAtom._pop);
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
      animation: _controller,
      builder: (context, child) {
        final t = const Cubic(.34, 1.56, .64, 1).transform(_controller.value);
        return Opacity(
          opacity: (0.45 + 0.55 * _controller.value).clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
