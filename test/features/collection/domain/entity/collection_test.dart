import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:flutter_test/flutter_test.dart';

CollectibleCard _card(String id, Rarity rarity, {String deckId = 'meridian'}) {
  return CollectibleCard(
    id: id,
    name: id,
    deckId: deckId,
    rarity: rarity,
    scaleLabel: 'Small',
    artAsset: 'a.png',
    description: 'd',
  );
}

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
      final deck = Deck(id: 'meridian', name: 'Meridian', cards: [
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
      final deck = Deck(id: 'd', name: 'D', cards: [_card('a', Rarity.common)]);
      expect(deck.rarityMix[Rarity.rare], 0);
    });
  });

  group('Collection', () {
    test('held count is cards held, not copies held', () {
      final gnomon = _card('gnomon', Rarity.common);
      final vernier = _card('vernier', Rarity.common);
      final collection = Collection(
        decks: [Deck(id: 'meridian', name: 'Meridian', cards: [gnomon, vernier])],
        holdingsByCardId: {
          'gnomon': Holding(card: gnomon, standardCopies: 5, specialCopies: 0),
        },
        walletPoints: 120,
        drawCost: 40,
      );
      expect(collection.heldCountFor('meridian'), 1);
      expect(collection.holdingsForDeck('meridian').length, 1);
    });

    test('a deck with nothing held reports zero', () {
      final collection = Collection(
        decks: [Deck(id: 'cinder', name: 'Cinder', cards: [_card('flint', Rarity.common, deckId: 'cinder')])],
        holdingsByCardId: const {},
        walletPoints: 15,
        drawCost: 40,
      );
      expect(collection.heldCountFor('cinder'), 0);
      expect(collection.holdingsForDeck('cinder'), isEmpty);
    });
  });
}
