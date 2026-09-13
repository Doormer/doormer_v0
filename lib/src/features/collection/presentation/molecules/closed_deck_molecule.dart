import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/card_back_atom.dart';

/// An unopened deck: three backs, leaning with the same tilt a duplicate stack
/// uses. Says *there are cards in here* without listing them, which is what
/// keeps the empty state inside the no-empty-frames rule.
class ClosedDeckMolecule extends StatelessWidget {
  final double? width;

  const ClosedDeckMolecule({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          alignment: Alignment.bottomCenter,
          angle: 5 * math.pi / 180,
          child: Opacity(opacity: 0.62, child: CardBackAtom(width: width)),
        ),
        Transform.rotate(
          alignment: Alignment.bottomCenter,
          angle: 2.5 * math.pi / 180,
          child: Opacity(opacity: 0.8, child: CardBackAtom(width: width)),
        ),
        CardBackAtom(width: width),
      ],
    );
  }
}
