import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:flutter_test/flutter_test.dart';

CollectibleCard _card(String id, Rarity rarity) {
  return CollectibleCard(
    id: id,
    name: id,
    rarity: rarity,
    scaleLabel: 'Small',
    artUrl: 'https://example.test/a.jpg',
    standardShatterQuarks: 5,
    specialShatterQuarks: 10,
    description: 'd',
  );
}

Deck _deck(List<CollectibleCard> cards, {int drawCost = 40}) =>
    Deck(id: 'meridian', name: 'Meridian', drawCost: drawCost, cards: cards);

void main() {
  group('Holding', () {
    test('total copies counts both printings', () {
      final h = Holding(
        card: _card('gnomon', Rarity.common),
        standardCopies: 2,
        specialCopies: 1,
      );
      expect(h.totalCopies, 3);
      expect(h.hasSpecial, isTrue);
    });
  });

  group('Deck', () {
    test('size is the card count and the mix counts each rarity', () {
      final deck = _deck([
        _card('a', Rarity.common),
        _card('b', Rarity.common),
        _card('c', Rarity.uncommon),
        _card('d', Rarity.rare),
      ]);
      expect(deck.size, 4);
      expect(deck.rarityMix[Rarity.common], 2);
      expect(deck.rarityMix[Rarity.uncommon], 1);
      expect(deck.rarityMix[Rarity.rare], 1);
    });

    test('an absent rarity is zero, never null', () {
      final deck = _deck([_card('a', Rarity.common)]);
      expect(deck.rarityMix[Rarity.rare], 0);
    });

    test('a draw is affordable at exactly its cost', () {
      final deck = _deck(const [], drawCost: 40);
      expect(deck.canAffordDraw(40), isTrue);
      expect(deck.quarksShortOfDraw(40), 0);
    });

    test('short of the cost, it says by how much', () {
      final deck = _deck(const [], drawCost: 40);
      expect(deck.canAffordDraw(15), isFalse);
      expect(deck.quarksShortOfDraw(15), 25);
    });
  });

  group('Collection', () {
    final gnomon = _card('gnomon', Rarity.common);
    final vernier = _card('vernier', Rarity.common);
    final orrery = _card('orrery', Rarity.rare);

    test('holdings follow the deck order, not the order they were drawn', () {
      final collection = Collection(
        deck: _deck([gnomon, vernier, orrery]),
        holdingsByCardId: {
          'orrery': Holding(card: orrery, standardCopies: 1, specialCopies: 0),
          'gnomon': Holding(card: gnomon, standardCopies: 1, specialCopies: 0),
        },
      );
      expect(collection.holdings.map((h) => h.card.id), ['gnomon', 'orrery']);
    });

    test('cards held counts cards, not copies', () {
      final collection = Collection(
        deck: _deck([gnomon, vernier]),
        holdingsByCardId: {
          'gnomon': Holding(card: gnomon, standardCopies: 5, specialCopies: 0),
        },
      );
      expect(collection.cardsHeld, 1);
      expect(collection.holdingOf('gnomon')?.totalCopies, 5);
      expect(collection.holdingOf('vernier'), isNull);
    });

    test('withCopies applies the counts a shatter answered with', () {
      final collection = Collection(
        deck: _deck([gnomon]),
        holdingsByCardId: {
          'gnomon': Holding(card: gnomon, standardCopies: 3, specialCopies: 1),
        },
      );
      final after =
          collection.withCopies('gnomon', standardCopies: 2, specialCopies: 1);
      expect(after.holdingOf('gnomon')?.standardCopies, 2);
      expect(after.holdingOf('gnomon')?.specialCopies, 1);
      expect(collection.holdingOf('gnomon')?.standardCopies, 3,
          reason: 'the original is left untouched');
    });

    test('a card left with no copies loses its holding', () {
      final collection = Collection(
        deck: _deck([gnomon, vernier]),
        holdingsByCardId: {
          'gnomon': Holding(card: gnomon, standardCopies: 1, specialCopies: 0),
          'vernier':
              Holding(card: vernier, standardCopies: 1, specialCopies: 0),
        },
      );
      final after =
          collection.withCopies('gnomon', standardCopies: 0, specialCopies: 0);
      expect(after.holdingOf('gnomon'), isNull);
      expect(after.cardsHeld, 1);
    });
  });
}
