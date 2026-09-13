import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';

class EmptyDeckParams {
  final int deckSize;
  final Map<Rarity, int> rarityMix;
  final int drawCost;
  final bool canAfford;

  /// Points still needed. Zero when [canAfford].
  final int pointsShort;

  final VoidCallback onDraw;

  const EmptyDeckParams({
    required this.deckSize,
    required this.rarityMix,
    required this.drawCost,
    required this.canAfford,
    required this.pointsShort,
    required this.onDraw,
  });
}
