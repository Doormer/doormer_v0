import 'package:doormer/src/features/collection/data/model/collection_response_models.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

HeldCardModel _heldCard(
  String cardId, {
  int standardCopies = 0,
  int specialCopies = 0,
}) =>
    HeldCardModel(
      cardId: cardId,
      name: 'Name of $cardId',
      rarity: Rarity.uncommon,
      artUrl: 'https://example.test/$cardId.jpg',
      scaleLabel: 'Medium',
      description: 'About $cardId',
      standardCopies: standardCopies,
      specialCopies: specialCopies,
      standardShatterQuarks: 11,
      specialShatterQuarks: 22,
    );

void main() {
  group('CardsResponseModel.toEntity', () {
    final collection = CardsResponseModel(
      quarkBalance: 40,
      deck: const DeckSummaryModel(
        deckId: 'meridian-01',
        name: 'Meridian',
        drawCost: 40,
      ),
      cards: [
        _heldCard('astrolabe', standardCopies: 1, specialCopies: 1),
        _heldCard('quadrant'),
        _heldCard('orrery', specialCopies: 1),
      ],
    ).toEntity();

    test('puts every card in the deck, held or not, in the order sent', () {
      expect(collection.deck.id, 'meridian-01');
      expect(collection.deck.name, 'Meridian');
      expect(collection.deck.drawCost, 40);
      expect(collection.deck.cards.map((c) => c.id),
          ['astrolabe', 'quadrant', 'orrery']);
    });

    test('gives a holding only to a card with copies', () {
      expect(collection.holdingOf('quadrant'), isNull,
          reason: 'a card with no copies must not leave an empty frame');
      expect(collection.holdingOf('astrolabe')?.standardCopies, 1);
      expect(collection.holdingOf('astrolabe')?.specialCopies, 1);
      expect(collection.holdingOf('orrery')?.specialCopies, 1);
      expect(collection.cardsHeld, 2);
    });

    test('keeps what the card shows and what it shatters for', () {
      final card = collection.deck.cards.first;
      expect(card.name, 'Name of astrolabe');
      expect(card.rarity, Rarity.uncommon);
      expect(card.artUrl, 'https://example.test/astrolabe.jpg');
      expect(card.scaleLabel, 'Medium');
      expect(card.description, 'About astrolabe');
      expect(card.shatterQuarksFor(CardVariant.standard), 11);
      expect(card.shatterQuarksFor(CardVariant.special), 22);
    });
  });

  test('DrawResponseModel.toEntity carries the drawn card and its count', () {
    final outcome = DrawResponseModel(
      quarkBalance: 0,
      card: _heldCard('gnomon'),
      variant: CardVariant.special,
      result: DrawResult.upgrade,
      copiesAfter: 2,
    ).toEntity();

    expect(outcome.card.id, 'gnomon');
    expect(outcome.variant, CardVariant.special);
    expect(outcome.result, DrawResult.upgrade);
    expect(outcome.copiesAfter, 2);
  });

  test('DeckProgressModel.toEntity keeps the progress through the deck', () {
    final progress = const DeckProgressModel(
      deckId: 'cinder-01',
      name: 'Cinder',
      cardsHeld: 0,
      cardsTotal: 6,
    ).toEntity();

    expect(progress.deckId, 'cinder-01');
    expect(progress.name, 'Cinder');
    expect(progress.cardsHeld, 0);
    expect(progress.cardsTotal, 6);
  });
}
