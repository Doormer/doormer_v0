import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/holding.dart';
import '../atoms/collectible_card_atom.dart';

/// A held card in the grid, sitting on a tilted stack when more than one copy
/// is held.
///
/// The tilt is the same gesture the reveal fan uses, tightened to grid size:
/// rotation has meant *more than one* everywhere in this feature. Offsetting
/// instead was tried and fails — at 104px a 5px offset is a line, and reads as
/// a drop shadow rather than a card.
class CardTileMolecule extends StatelessWidget {
  final Holding holding;
  final double width;
  final VoidCallback? onTap;

  const CardTileMolecule({
    super.key,
    required this.holding,
    required this.width,
    this.onTap,
  });

  /// Layers *behind* the front card. Capped at two: the grid answers
  /// "one, a couple, or a pile" and the badge answers "how many".
  static int layersFor(int copies) => anglesFor(copies).length;

  /// The rear layers' angles, **ordered back to front**.
  ///
  /// A pair opens to 3°; three or more splay to 5° and 2.5°. The list order is
  /// the paint order, and in a [Stack] later children paint on top — so the
  /// steepest angle must come first or the deepest card ends up in front of
  /// the shallower one.
  static List<double> anglesFor(int copies) {
    if (copies <= 1) return const [];
    if (copies == 2) return const [3.0];
    return const [5.0, 2.5];
  }

  @override
  Widget build(BuildContext context) {
    final copies = holding.totalCopies;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Painted first so they sit behind the art but above the surface,
          // and in back-to-front order so the steepest tilt is deepest.
          for (final angle in anglesFor(copies))
            Transform.rotate(
              alignment: Alignment.bottomCenter,
              angle: angle * math.pi / 180,
              child: Container(
                width: width.w,
                height: width.w / CollectibleCardAtom.aspectRatio,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2450),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          CollectibleCardAtom(
            card: holding.card,
            width: width,
            copies: copies,
          ),
        ],
      ),
    );
  }
}
