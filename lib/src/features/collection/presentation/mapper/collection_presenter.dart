import '../../domain/entity/collection.dart';
import '../../domain/entity/deck.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/entity/draw_outcome.dart';
import '../params/deck_row_params.dart';
import '../params/empty_deck_params.dart';

/// Turns entities into the plain holders the widgets take. Pure, and invoked
/// from the page and the template only — nothing below them builds its own
/// params.
class CollectionPresenter {
  const CollectionPresenter._();

  static List<DeckRowParams> deckRows({
    required List<DeckProgress> decks,
    required String? selectedDeckId,
    required bool isRail,
    required void Function(String deckId) onSelect,
  }) {
    return [
      for (final deck in decks)
        DeckRowParams(
          deckId: deck.deckId,
          name: deck.name,
          held: deck.cardsHeld,
          total: deck.cardsTotal,
          isSelected: deck.deckId == selectedDeckId,
          showFlag: !isRail,
          onTap: () => onSelect(deck.deckId),
        ),
    ];
  }

  static EmptyDeckParams emptyDeck({
    required Deck deck,
    required int quarkBalance,
    required bool isDrawing,
    required void Function() onDraw,
  }) {
    return EmptyDeckParams(
      deckSize: deck.size,
      rarityMix: deck.rarityMix,
      drawCost: deck.drawCost,
      canAfford: deck.canAffordDraw(quarkBalance),
      quarksShortLabel: quarksShortLabel(deck.quarksShortOfDraw(quarkBalance)),
      isDrawing: isDrawing,
      onDraw: onDraw,
    );
  }

  /// The wallet: "40 quarks", or "1 quark".
  static String quarkBalanceLabel(int quarkBalance) =>
      '$quarkBalance ${_quarkWord(quarkBalance)}';

  /// Under a draw button the student can't afford yet: "25 more quarks to
  /// draw", or "1 more quark to draw".
  static String quarksShortLabel(int quarksShort) =>
      '$quarksShort more ${_quarkWord(quarksShort)} to draw';

  static String _quarkWord(int count) => count == 1 ? 'quark' : 'quarks';

  /// The quiet line under a reveal's headline.
  ///
  /// Transcribed from the mockup's three outcomes: deck progress for a new
  /// card, reassurance that the plain copy survives an upgrade, and what a
  /// spare is worth for a duplicate. The headline says what happened; this
  /// says what it means. [collectionAfterDraw] is null when reading the deck
  /// after the draw failed, and each line then says only what it still knows.
  static String revealSupportingLine({
    required DrawOutcome outcome,
    required String deckName,
    required Collection? collectionAfterDraw,
  }) {
    switch (outcome.result) {
      case DrawResult.newCard:
        if (collectionAfterDraw == null) return 'Added to $deckName';
        return '$deckName is ${collectionAfterDraw.cardsHeld} '
            'of ${collectionAfterDraw.deck.size}';
      case DrawResult.upgrade:
        return 'You keep the standard one.';
      case DrawResult.duplicate:
        // The same number the card detail will offer, so it is worked out
        // from the holding after the draw rather than from the drawn copy.
        final holding = collectionAfterDraw?.holdingOf(outcome.card.id);
        if (holding == null) return 'You can shatter a spare for quarks.';
        return 'Shatter one for '
            '${holding.card.shatterQuarksFor(holding.variantToShatter)} quarks';
    }
  }
}
