import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';

class EmptyDeckParams {
  final int deckSize;
  final Map<Rarity, int> rarityMix;
  final String drawLabel;
  final bool canAfford;

  /// How far short of a draw the student is, as the screen says it:
  /// "25 more quarks to draw. Answer questions to earn quarks.".
  /// Shown only when not [canAfford].
  final String quarksShortLabel;

  /// A draw is in flight, so the button shows a spinner.
  final bool isDrawing;

  final VoidCallback onDraw;

  const EmptyDeckParams({
    required this.deckSize,
    required this.rarityMix,
    required this.drawLabel,
    required this.canAfford,
    required this.quarksShortLabel,
    required this.isDrawing,
    required this.onDraw,
  });
}
