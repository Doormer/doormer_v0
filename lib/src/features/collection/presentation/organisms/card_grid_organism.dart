import 'package:doormer/src/shared/design/atomic/atoms/rise_in_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/holding.dart';
import '../molecules/card_tile_molecule.dart';

/// The held cards of one deck.
///
/// **`Wrap`, never `GridView`.** A grid with a fixed cross-axis extent reserves
/// a full row of slots, so a partial last row cannot centre — four cards in a
/// three-wide grid strand the fourth on the left with two empty slots beside
/// it. `Wrap` lays out only the children that exist.
///
/// Cards not held are absent. There are no placeholders, silhouettes or empty
/// frames: a collection should not read as a checklist of failures.
///
/// Cards arrive rather than appear, each a small beat behind the one before —
/// [RiseInAtom] already owns that stagger and already honours reduced motion,
/// so the grid only has to hand it each tile's place in line.
class CardGridOrganism extends StatelessWidget {
  final List<Holding> holdings;
  final double cardWidth;
  final void Function(Holding holding)? onCardTap;

  const CardGridOrganism({
    super.key,
    required this.holdings,
    required this.cardWidth,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18.w,
      runSpacing: 20.h,
      children: [
        for (final (index, holding) in holdings.indexed)
          RiseInAtom(
            order: index,
            child: CardTileMolecule(
              holding: holding,
              width: cardWidth,
              onTap: onCardTap == null ? null : () => onCardTap!(holding),
            ),
          ),
      ],
    );
  }
}
