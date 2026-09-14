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
  /// Columns a filled grid uses on a phone.
  static const int phoneColumns = 2;

  final List<Holding> holdings;

  /// The card width on a wide window. Ignored when [fillWidth] is set, because
  /// the width is then whatever two columns divide into.
  final double cardWidth;

  /// Phone behaviour: two columns spanning the full width, edge to edge.
  ///
  /// The design asks for two different grids, not one grid at two sizes —
  /// "Desktop: centred. Phone: fills the width, two columns, edge to edge",
  /// because a phone has no spare horizontal space to give away.
  final bool fillWidth;

  final void Function(Holding holding)? onCardTap;

  const CardGridOrganism({
    super.key,
    required this.holdings,
    required this.cardWidth,
    this.fillWidth = false,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = 18.w;
    final runSpacing = 20.h;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        // CardTileMolecule takes design units and applies `.w` itself, so a
        // width measured in real pixels has to be converted back or it scales
        // twice. `1.w` is exactly that factor.
        final scale = 1.0.w;
        final width = fillWidth && available.isFinite
            ? ((available - spacing * (phoneColumns - 1)) / phoneColumns) /
                scale
            : cardWidth;

        return SizedBox(
          // Full width on purpose. Inside a Column with
          // CrossAxisAlignment.start the Wrap would otherwise shrink to its
          // own content, and WrapAlignment.center would have nothing left to
          // centre within — which is what left-aligned the whole grid.
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: runSpacing,
            children: [
              for (final (index, holding) in holdings.indexed)
                RiseInAtom(
                  order: index,
                  child: CardTileMolecule(
                    holding: holding,
                    width: width,
                    onTap: onCardTap == null ? null : () => onCardTap!(holding),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
