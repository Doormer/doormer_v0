import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/collectible_card.dart';
import '../../domain/entity/collection.dart';
import '../../domain/entity/deck.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/entity/draw_outcome.dart';
import '../../domain/entity/holding.dart';

// The collection API's responses, one class per API type and named after it.
// Each `fromJson` throws when a field is missing, has the wrong type, or holds
// a value the app does not know; the data source reports that as an
// unreadable response. `toEntity` turns a response into the domain's terms.

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

  DeckProgress toEntity() => DeckProgress(
        deckId: deckId,
        name: name,
        cardsHeld: cardsHeld,
        cardsTotal: cardsTotal,
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

  /// The card alone. Its copy counts become a [Holding] in
  /// [CardsResponseModel.toEntity].
  CollectibleCard toEntity() => CollectibleCard(
        id: cardId,
        name: name,
        rarity: rarity,
        scaleLabel: scaleLabel,
        artUrl: artUrl,
        standardShatterQuarks: standardShatterQuarks,
        specialShatterQuarks: specialShatterQuarks,
        description: description,
      );
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

  /// Every card goes into the deck, but only a card with copies gets a
  /// holding, so the grid stays free of empty frames.
  Collection toEntity() {
    final deckCards = <CollectibleCard>[];
    final holdingsByCardId = <String, Holding>{};
    for (final held in cards) {
      final card = held.toEntity();
      deckCards.add(card);
      if (held.standardCopies + held.specialCopies > 0) {
        holdingsByCardId[card.id] = Holding(
          card: card,
          standardCopies: held.standardCopies,
          specialCopies: held.specialCopies,
        );
      }
    }
    return Collection(
      deck: Deck(
        id: deck.deckId,
        name: deck.name,
        drawCost: deck.drawCost,
        cards: deckCards,
      ),
      holdingsByCardId: holdingsByCardId,
    );
  }
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

  DrawOutcome toEntity() => DrawOutcome(
        card: card.toEntity(),
        variant: variant,
        result: result,
        copiesAfter: copiesAfter,
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

/// A card in a friend's collection: as [HeldCardModel], without what a
/// shatter pays. Friends never shatter each other's cards.
class FriendHeldCardModel {
  final String cardId;
  final String name;
  final Rarity rarity;
  final String artUrl;
  final String scaleLabel;
  final String description;
  final int standardCopies;
  final int specialCopies;

  const FriendHeldCardModel({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.artUrl,
    required this.scaleLabel,
    required this.description,
    required this.standardCopies,
    required this.specialCopies,
  });

  factory FriendHeldCardModel.fromJson(Map<String, dynamic> json) {
    // An empty attribute map arrives as null.
    final attributes = json['attributes'] as Map<String, dynamic>? ?? const {};
    return FriendHeldCardModel(
      cardId: json['card_id'] as String,
      name: json['name'] as String,
      rarity: _rarity(json['rarity'] as String),
      artUrl: json['art_url'] as String,
      scaleLabel: attributes['scale_label'] as String? ?? '',
      description: attributes['description'] as String? ?? '',
      standardCopies: json['standard_copies'] as int,
      specialCopies: json['special_copies'] as int,
    );
  }

  /// The card alone, worth nothing when shattered: the card detail shows no
  /// Shatter for a friend's card.
  CollectibleCard toEntity() => CollectibleCard(
        id: cardId,
        name: name,
        rarity: rarity,
        scaleLabel: scaleLabel,
        artUrl: artUrl,
        standardShatterQuarks: 0,
        specialShatterQuarks: 0,
        description: description,
      );
}

/// The answer to `/friends/decks`: the friend, and their deck list, as
/// `/collection/decks` sends it, without the quark balance.
class FriendDecksResponseModel {
  final FriendSummaryModel friend;
  final List<DeckProgressModel> decks;

  const FriendDecksResponseModel({required this.friend, required this.decks});

  factory FriendDecksResponseModel.fromJson(Map<String, dynamic> json) =>
      FriendDecksResponseModel(
        friend:
            FriendSummaryModel.fromJson(json['friend'] as Map<String, dynamic>),
        decks: [
          for (final deck in json['decks'] as List<dynamic>)
            DeckProgressModel.fromJson(deck as Map<String, dynamic>),
        ],
      );
}

/// The answer to `/friends/cards`: the friend, the deck, and every card in
/// it, held or not, without the quark balance or the draw cost.
class FriendCardsResponseModel {
  final FriendSummaryModel friend;
  final String deckId;
  final String deckName;
  final List<FriendHeldCardModel> cards;

  const FriendCardsResponseModel({
    required this.friend,
    required this.deckId,
    required this.deckName,
    required this.cards,
  });

  factory FriendCardsResponseModel.fromJson(Map<String, dynamic> json) {
    final deck = json['deck'] as Map<String, dynamic>;
    return FriendCardsResponseModel(
      friend:
          FriendSummaryModel.fromJson(json['friend'] as Map<String, dynamic>),
      deckId: deck['deck_id'] as String,
      deckName: deck['name'] as String,
      cards: [
        for (final card in json['cards'] as List<dynamic>)
          FriendHeldCardModel.fromJson(card as Map<String, dynamic>),
      ],
    );
  }

  /// As [CardsResponseModel.toEntity]: only a card with copies gets a
  /// holding. A friend's deck has no draw cost, since no one draws from it
  /// here.
  Collection toEntity() {
    final deckCards = <CollectibleCard>[];
    final holdingsByCardId = <String, Holding>{};
    for (final held in cards) {
      final card = held.toEntity();
      deckCards.add(card);
      if (held.standardCopies + held.specialCopies > 0) {
        holdingsByCardId[card.id] = Holding(
          card: card,
          standardCopies: held.standardCopies,
          specialCopies: held.specialCopies,
        );
      }
    }
    return Collection(
      deck: Deck(id: deckId, name: deckName, drawCost: 0, cards: deckCards),
      holdingsByCardId: holdingsByCardId,
    );
  }
}
