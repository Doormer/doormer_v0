import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// The two things that mark where the student is standing.
///
/// A ring fires once the moment a node becomes current — that is the signal
/// that the page moved. As it dies a halo takes over and beats, which is what
/// makes the node findable at a glance in a trail too long to see at once.
///
/// **Divergence from the design, deliberate:** the prototype beats forever.
/// CSS lets the compositor handle that; a Flutter controller repainting a
/// shadow at 60fps forever never lets the frame loop idle, on a page a student
/// may leave open for the length of a problem. So the halo beats [_beats]
/// times and then rests. Nothing is lost — the node is already pink, filled,
/// enlarged and glowing at rest; the beat is emphasis, not the marker.
class CurrentNodeHaloAtom extends StatefulWidget {
  final double size;
  final bool marker;
  final Widget child;

  const CurrentNodeHaloAtom({
    super.key,
    required this.size,
    required this.marker,
    required this.child,
  });

  @override
  State<CurrentNodeHaloAtom> createState() => _CurrentNodeHaloAtomState();
}

class _CurrentNodeHaloAtomState extends State<CurrentNodeHaloAtom>
    with TickerProviderStateMixin {
  static const int _beats = 6;
  static const Duration _beatPeriod = Duration(milliseconds: 1700);

  late final AnimationController _ring;
  late final AnimationController _beat;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Built even when motion is off, so dispose never has to reach back into a
    // deactivated element to create the ticker it is about to throw away.
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _beat = AnimationController(
      vsync: this,
      duration: _beatPeriod * _beats,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !MotionPolicy.idle(context)) return;
    _started = true;
    // The beat picks up exactly as the ring dies, which is the delay the
    // design gives it.
    _ring.forward().then((_) {
      if (mounted) _beat.forward();
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MotionPolicy.idle(context)) return widget.child;

    final radius = widget.marker
        ? BorderRadius.circular(widget.size * 0.32)
        : BorderRadius.circular(widget.size);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _beat,
              builder: (context, _) {
                // A whole number of cycles, so the halo lands back on its
                // resting glow rather than stopping mid-pulse.
                final t =
                    (1 - math.cos(2 * math.pi * _beats * _beat.value)) / 2;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color:
                            QuestPalette.pink.withValues(alpha: 0.30 * (1 - t)),
                        spreadRadius: 3 + 7 * t,
                      ),
                      BoxShadow(
                        color: QuestPalette.pink
                            .withValues(alpha: 0.55 + 0.25 * t),
                        blurRadius: 20 + 12 * t,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ring,
              builder: (context, _) {
                if (_ring.isCompleted) return const SizedBox.shrink();
                final t = const Cubic(.18, .72, .28, 1).transform(_ring.value);
                return Transform.scale(
                  scale: 1 + 1.8 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color:
                            QuestPalette.pink.withValues(alpha: 0.95 * (1 - t)),
                        width: 3 - 2 * t,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
