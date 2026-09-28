import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collectible_card.dart';
import '../../domain/entity/collection.dart';
import '../../domain/entity/deck.dart';
import '../../domain/entity/draw_outcome.dart';
import '../../domain/entity/holding.dart';

/// Parses the bundled collection asset. Lives in `data/` because the JSON shape
/// is a transport detail, not something the domain should know.
class CollectionModel {
  const CollectionModel._();

  static Rarity _rarity(String raw) {
    switch (raw) {
      case 'common':
        return Rarity.common;
      case 'uncommon':
        return Rarity.uncommon;
      case 'rare':
        return Rarity.rare;
      default:
        throw FormatException('Unknown rarity: $raw');
    }
  }

  static CardVariant _variant(String raw) {
    switch (raw) {
      case 'standard':
        return CardVariant.standard;
      case 'special':
        return CardVariant.special;
      default:
        throw FormatException('Unknown variant: $raw');
    }
  }

  static DrawResult _result(String raw) {
    switch (raw) {
      case 'newCard':
        return DrawResult.newCard;
      case 'upgrade':
        return DrawResult.upgrade;
      case 'duplicate':
        return DrawResult.duplicate;
      default:
        throw FormatException('Unknown draw result: $raw');
    }
  }

  static List<Deck> decksFrom(Map<String, dynamic> json) {
    final rawDecks = json['decks'] as List<dynamic>;
    return rawDecks.map((rawDeck) {
      final deck = rawDeck as Map<String, dynamic>;
      final deckId = deck['id'] as String;
      final cards = (deck['cards'] as List<dynamic>).map((rawCard) {
        final card = rawCard as Map<String, dynamic>;
        return CollectibleCard(
          id: card['id'] as String,
          name: card['name'] as String,
          deckId: deckId,
          rarity: _rarity(card['rarity'] as String),
          scaleLabel: card['scaleLabel'] as String,
          artUrl: card['artUrl'] as String,
          standardShatterQuarks: card['standardShatterQuarks'] as int,
          specialShatterQuarks: card['specialShatterQuarks'] as int,
          description: card['description'] as String,
        );
      }).toList();
      return Deck(id: deckId, name: deck['name'] as String, cards: cards);
    }).toList();
  }

  static Collection collectionFrom(Map<String, dynamic> json) {
    final decks = decksFrom(json);
    final byId = <String, CollectibleCard>{
      for (final deck in decks)
        for (final card in deck.cards) card.id: card,
    };

    final holdings = <String, Holding>{};
    for (final rawHolding in json['holdings'] as List<dynamic>) {
      final holding = rawHolding as Map<String, dynamic>;
      final cardId = holding['cardId'] as String;
      final card = byId[cardId];
      if (card == null) {
        throw FormatException('Holding names an unknown card: $cardId');
      }
      holdings[cardId] = Holding(
        card: card,
        standardCopies: holding['standardCopies'] as int,
        specialCopies: holding['specialCopies'] as int,
      );
    }

    return Collection(
      decks: decks,
      holdingsByCardId: holdings,
      quarkBalance: json['quarkBalance'] as int,
      drawCost: json['drawCost'] as int,
    );
  }

  /// Resolves the sequence against the decks. `copiesAfter` is left at zero
  /// here — only the repository knows how many copies are held when a draw is
  /// actually spent, so it fills this in as it replays.
  static List<DrawOutcome> sequenceFrom(Map<String, dynamic> json) {
    final decks = decksFrom(json);
    final byId = <String, CollectibleCard>{
      for (final deck in decks)
        for (final card in deck.cards) card.id: card,
    };

    return (json['drawSequence'] as List<dynamic>).map((rawStep) {
      final step = rawStep as Map<String, dynamic>;
      final cardId = step['cardId'] as String;
      final card = byId[cardId];
      if (card == null) {
        throw FormatException('Draw sequence names an unknown card: $cardId');
      }
      return DrawOutcome(
        card: card,
        variant: _variant(step['variant'] as String),
        result: _result(step['result'] as String),
        copiesAfter: 0,
      );
    }).toList();
  }
}
