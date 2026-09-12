import 'dart:math' as math;

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';

/// A ring that breathes outward a few times, saying the node underneath can be
/// gone back to.
class InviteRingAtom extends StatelessWidget {
  final double size;
  final bool marker;
  final Widget child;

  const InviteRingAtom({
    super.key,
    required this.size,
    required this.marker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IdleBeatAtom(
      period: const Duration(milliseconds: 3400),
      beats: 3,
      child: child,
      builder: (context, phase, child) {
        // Out and gone, then back to the start: the ring leaves rather than
        // fading where it stands.
        final out = (1 - math.cos(phase * 2 * math.pi)) / 2;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            child!,
            if (out > 0)
              Positioned(
                left: -6,
                right: -6,
                top: -6,
                bottom: -6,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 1 + 0.16 * out,
                    child: DecoratedBox(
                      key: const Key('trail_invite_ring'),
                      decoration: BoxDecoration(
                        shape: marker ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius:
                            marker ? BorderRadius.circular(size * 0.42) : null,
                        border: Border.all(
                          color: QuestPalette.violet
                              .withValues(alpha: 0.5 * (1 - out)),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
