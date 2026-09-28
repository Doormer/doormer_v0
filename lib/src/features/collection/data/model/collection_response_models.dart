import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/draw_outcome.dart';

// The collection API's responses, one class per API type and named after it.
// Each `fromJson` throws when a field is missing, has the wrong type, or holds
// a value the app does not know; the data source reports that as an
// unreadable response.

Rarity _rarity(String raw) => switch (raw) {
      'common' => Rarity.common,
      'uncommon' => Rarity.uncommon,
      'rare' => Rarity.rare,
      _ => throw FormatException('Unknown rarity: $raw'),
    };

CardVariant _variant(String raw) => switch (raw) {
      'standard' => CardVariant.standard,
      'special' => CardVariant.special,
      _ => throw FormatException('Unknown variant: $raw'),
    };

DrawResult _result(String raw) => switch (raw) {
      'new_card' => DrawResult.newCard,
      'upgrade' => DrawResult.upgrade,
      'duplicate' => DrawResult.duplicate,
      _ => throw FormatException('Unknown draw result: $raw'),
    };

/// One row of the deck list. The API also sends `draw_cost`,
/// `cards_with_special` and `rarity_mix`; the deck list does not show them.
class DeckProgressModel {
  final String deckId;
  final String name;
  final int cardsHeld;
  final int cardsTotal;

  const DeckProgressModel({
    required this.deckId,
    required this.name,
    required this.cardsHeld,
    required this.cardsTotal,
  });

  factory DeckProgressModel.fromJson(Map<String, dynamic> json) =>
      DeckProgressModel(
        deckId: json['deck_id'] as String,
        name: json['name'] as String,
        cardsHeld: json['cards_held'] as int,
        cardsTotal: json['cards_total'] as int,
      );
}

class DecksResponseModel {
  final int quarkBalance;
  final List<DeckProgressModel> decks;

  const DecksResponseModel({required this.quarkBalance, required this.decks});

  factory DecksResponseModel.fromJson(Map<String, dynamic> json) =>
      DecksResponseModel(
        quarkBalance: json['quark_balance'] as int,
        decks: [
          for (final deck in json['decks'] as List<dynamic>)
            DeckProgressModel.fromJson(deck as Map<String, dynamic>),
        ],
      );
}

/// A card and how many copies of it the student holds. Both counts are zero
/// for a card not held yet.
class HeldCardModel {
  final String cardId;
  final String name;
  final Rarity rarity;
  final String artUrl;
  final String scaleLabel;
  final String description;
  final int standardCopies;
  final int specialCopies;
  final int standardShatterQuarks;
  final int specialShatterQuarks;

  const HeldCardModel({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.artUrl,
    required this.scaleLabel,
    required this.description,
    required this.standardCopies,
    required this.specialCopies,
    required this.standardShatterQuarks,
    required this.specialShatterQuarks,
  });

  factory HeldCardModel.fromJson(Map<String, dynamic> json) {
    // An empty attribute map arrives as null.
    final attributes = json['attributes'] as Map<String, dynamic>? ?? const {};
    return HeldCardModel(
      cardId: json['card_id'] as String,
      name: json['name'] as String,
      rarity: _rarity(json['rarity'] as String),
      artUrl: json['art_url'] as String,
      scaleLabel: attributes['scale_label'] as String? ?? '',
      description: attributes['description'] as String? ?? '',
      standardCopies: json['standard_copies'] as int,
      specialCopies: json['special_copies'] as int,
      standardShatterQuarks: json['standard_shatter_quarks'] as int,
      specialShatterQuarks: json['special_shatter_quarks'] as int,
    );
  }
}

/// The deck a `cards` response is about.
class DeckSummaryModel {
  final String deckId;
  final String name;
  final int drawCost;

  const DeckSummaryModel({
    required this.deckId,
    required this.name,
    required this.drawCost,
  });

  factory DeckSummaryModel.fromJson(Map<String, dynamic> json) =>
      DeckSummaryModel(
        deckId: json['deck_id'] as String,
        name: json['name'] as String,
        drawCost: json['draw_cost'] as int,
      );
}

class CardsResponseModel {
  final int quarkBalance;
  final DeckSummaryModel deck;

  /// Every card in the deck, held or not.
  final List<HeldCardModel> cards;

  const CardsResponseModel({
    required this.quarkBalance,
    required this.deck,
    required this.cards,
  });

  factory CardsResponseModel.fromJson(Map<String, dynamic> json) =>
      CardsResponseModel(
        quarkBalance: json['quark_balance'] as int,
        deck: DeckSummaryModel.fromJson(json['deck'] as Map<String, dynamic>),
        cards: [
          for (final card in json['cards'] as List<dynamic>)
            HeldCardModel.fromJson(card as Map<String, dynamic>),
        ],
      );
}

class DrawResponseModel {
  final int quarkBalance;

  /// The drawn card. Its copy counts are always zero: [copiesAfter] is the
  /// count that matters.
  final HeldCardModel card;
  final CardVariant variant;
  final DrawResult result;
  final int copiesAfter;

  const DrawResponseModel({
    required this.quarkBalance,
    required this.card,
    required this.variant,
    required this.result,
    required this.copiesAfter,
  });

  factory DrawResponseModel.fromJson(Map<String, dynamic> json) =>
      DrawResponseModel(
        quarkBalance: json['quark_balance'] as int,
        card: HeldCardModel.fromJson(json['card'] as Map<String, dynamic>),
        variant: _variant(json['variant'] as String),
        result: _result(json['result'] as String),
        copiesAfter: json['copies_after'] as int,
      );
}

/// The API also sends `quarks_gained` and `card_id`; the app needs neither,
/// because the new balance and the counts say everything that changed.
class ShatterResponseModel {
  final int quarkBalance;
  final int standardCopies;
  final int specialCopies;

  const ShatterResponseModel({
    required this.quarkBalance,
    required this.standardCopies,
    required this.specialCopies,
  });

  factory ShatterResponseModel.fromJson(Map<String, dynamic> json) =>
      ShatterResponseModel(
        quarkBalance: json['quark_balance'] as int,
        standardCopies: json['standard_copies'] as int,
        specialCopies: json['special_copies'] as int,
      );
}
