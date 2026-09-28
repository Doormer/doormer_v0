import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';

class EmptyDeckParams {
  final int deckSize;
  final Map<Rarity, int> rarityMix;
  final int drawCost;
  final bool canAfford;

  /// Quarks still needed. Zero when [canAfford].
  final int quarksShort;

  final VoidCallback onDraw;

  const EmptyDeckParams({
    required this.deckSize,
    required this.rarityMix,
    required this.drawCost,
    required this.canAfford,
    required this.quarksShort,
    required this.onDraw,
  });
}
