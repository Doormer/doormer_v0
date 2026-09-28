import '../../domain/entity/collection.dart';
import '../../domain/entity/draw_outcome.dart';
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
      quarksShort: collection.quarksShortOfDraw,
      onDraw: onDraw,
    );
  }

  /// The quiet line under a reveal's headline.
  ///
  /// Transcribed from the mockup's three outcomes: deck progress for a new
  /// card, reassurance that the plain copy survives an upgrade, and what a
  /// spare is worth for a duplicate. The headline says what happened; this
  /// says what it means.
  static String revealSupportingLine({
    required Collection collection,
    required DrawOutcome outcome,
  }) {
    switch (outcome.result) {
      case DrawResult.newCard:
        final deck =
            collection.decks.firstWhere((d) => d.id == outcome.card.deckId);
        return '${deck.name} is '
            '${collection.heldCountFor(deck.id)} of ${deck.size}';
      case DrawResult.upgrade:
        return 'You keep the standard one.';
      case DrawResult.duplicate:
        // The same number the card detail will offer, so it is worked out
        // from the holding after the draw rather than from the drawn copy.
        final holding = collection.holdingsByCardId[outcome.card.id];
        if (holding == null) return 'You can shatter a spare for quarks.';
        return 'Shatter one for '
            '${outcome.card.shatterQuarksFor(holding.variantToShatter)} quarks';
    }
  }
}
