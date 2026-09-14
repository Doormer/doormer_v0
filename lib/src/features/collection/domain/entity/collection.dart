import 'package:equatable/equatable.dart';

import 'deck.dart';
import 'holding.dart';

/// Everything a student has, across every deck, plus the wallet the draw is
/// paid from.
class Collection extends Equatable {
  final List<Deck> decks;
  final Map<String, Holding> holdingsByCardId;
  final int walletPoints;
  final int drawCost;

  const Collection({
    required this.decks,
    required this.holdingsByCardId,
    required this.walletPoints,
    required this.drawCost,
  });

  bool get canAffordDraw => walletPoints >= drawCost;

  /// Points still needed before a draw is possible. Zero when affordable.
  int get pointsShortOfDraw =>
      canAffordDraw ? 0 : drawCost - walletPoints;

  /// Held cards for one deck, in the deck's own card order so the grid is
  /// stable as it fills rather than reordering on every draw.
  List<Holding> holdingsForDeck(String deckId) {
    final deck = decks.firstWhere((d) => d.id == deckId);
    return deck.cards
        .map((c) => holdingsByCardId[c.id])
        .whereType<Holding>()
        .toList();
  }

  int heldCountFor(String deckId) => holdingsForDeck(deckId).length;

  Collection copyWith({
    Map<String, Holding>? holdingsByCardId,
    int? walletPoints,
  }) {
    return Collection(
      decks: decks,
      holdingsByCardId: holdingsByCardId ?? this.holdingsByCardId,
      walletPoints: walletPoints ?? this.walletPoints,
      drawCost: drawCost,
    );
  }

  @override
  List<Object?> get props => [decks, holdingsByCardId, walletPoints, drawCost];
}
