import '../../domain/entity/collection.dart';
import '../params/deck_row_params.dart';
import '../params/empty_deck_params.dart';

/// Turns entities into the plain holders the widgets take. Pure, and invoked
/// from the page only — nothing below the page builds its own params.
class CollectionPresenter {
  const CollectionPresenter._();

  static List<DeckRowParams> deckRows({
    required Collection collection,
    required String? selectedDeckId,
    required bool isRail,
    required void Function(String deckId) onSelect,
  }) {
    return collection.decks.map((deck) {
      return DeckRowParams(
        deckId: deck.id,
        name: deck.name,
        held: collection.heldCountFor(deck.id),
        total: deck.size,
        isSelected: deck.id == selectedDeckId,
        showFlag: !isRail,
        onTap: () => onSelect(deck.id),
      );
    }).toList();
  }

  static EmptyDeckParams emptyDeck({
    required Collection collection,
    required String deckId,
    required void Function() onDraw,
  }) {
    final deck = collection.decks.firstWhere((d) => d.id == deckId);
    return EmptyDeckParams(
      deckSize: deck.size,
      rarityMix: deck.rarityMix,
      drawCost: collection.drawCost,
      canAfford: collection.canAffordDraw,
      pointsShort: collection.pointsShortOfDraw,
      onDraw: onDraw,
    );
  }
}
