import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';

class EmptyDeckParams {
  final int deckSize;
  final Map<Rarity, int> rarityMix;
  final int drawCost;
  final bool canAfford;

  /// Quarks still needed. Zero when [canAfford].
  final int quarksShort;

  /// A draw is in flight, so the button shows a spinner.
  final bool isDrawing;

  final VoidCallback onDraw;

  const EmptyDeckParams({
    required this.deckSize,
    required this.rarityMix,
    required this.drawCost,
    required this.canAfford,
    required this.quarksShort,
    required this.isDrawing,
    required this.onDraw,
  });
}
