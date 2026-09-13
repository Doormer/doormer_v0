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
  static const List<double> _angles = [5.0, 2.5];

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
  static int layersFor(int copies) {
    if (copies <= 1) return 0;
    if (copies == 2) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final copies = holding.totalCopies;
    final layers = layersFor(copies);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Painted first so they sit behind the art but above the surface.
          for (var i = layers - 1; i >= 0; i--)
            Transform.rotate(
              alignment: Alignment.bottomCenter,
              angle: _angles[i] * math.pi / 180,
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
