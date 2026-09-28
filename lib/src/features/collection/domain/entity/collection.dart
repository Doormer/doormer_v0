import 'package:equatable/equatable.dart';

import 'deck.dart';
import 'holding.dart';

/// One student's cards in one deck.
class Collection extends Equatable {
  final Deck deck;

  /// Only cards with at least one copy. A card never held has no holding,
  /// which is what keeps the grid free of empty frames.
  final Map<String, Holding> holdingsByCardId;

  const Collection({required this.deck, required this.holdingsByCardId});

  /// Held cards in the deck's own card order, so the grid is stable as it
  /// fills rather than reordering on every draw.
  List<Holding> get holdings => deck.cards
      .map((c) => holdingsByCardId[c.id])
      .whereType<Holding>()
      .toList();

  /// Cards held, not copies held.
  int get cardsHeld => holdings.length;

  Holding? holdingOf(String cardId) => holdingsByCardId[cardId];

  /// The collection after a shatter left [cardId] with these copy counts. A
  /// card left with no copies loses its holding.
  Collection withCopies(
    String cardId, {
    required int standardCopies,
    required int specialCopies,
  }) {
    final card = deck.cards.firstWhere((c) => c.id == cardId);
    final holdings = Map<String, Holding>.of(holdingsByCardId);
    if (standardCopies + specialCopies == 0) {
      holdings.remove(cardId);
    } else {
      holdings[cardId] = Holding(
        card: card,
        standardCopies: standardCopies,
        specialCopies: specialCopies,
      );
    }
    return Collection(deck: deck, holdingsByCardId: holdings);
  }

  @override
  List<Object?> get props => [deck, holdingsByCardId];
}
