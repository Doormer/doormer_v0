import 'package:equatable/equatable.dart';

import 'deck.dart';
import 'holding.dart';

/// Everything a student has, across every deck, plus the wallet the draw is
/// paid from.
class Collection extends Equatable {
  final List<Deck> decks;
  final Map<String, Holding> holdingsByCardId;
  final int quarkBalance;
  final int drawCost;

  const Collection({
    required this.decks,
    required this.holdingsByCardId,
    required this.quarkBalance,
    required this.drawCost,
  });

  bool get canAffordDraw => quarkBalance >= drawCost;

  /// Quarks still needed before a draw is possible. Zero when affordable.
  int get quarksShortOfDraw => canAffordDraw ? 0 : drawCost - quarkBalance;

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
    int? quarkBalance,
  }) {
    return Collection(
      decks: decks,
      holdingsByCardId: holdingsByCardId ?? this.holdingsByCardId,
      quarkBalance: quarkBalance ?? this.quarkBalance,
      drawCost: drawCost,
    );
  }

  @override
  List<Object?> get props => [decks, holdingsByCardId, quarkBalance, drawCost];
}
