import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:flutter_test/flutter_test.dart';

const _card = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  deckId: 'meridian',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/gnomon.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'A shadow stick.',
);

void main() {
  group('variantToShatter', () {
    test('takes a standard copy while any is held, keeping the special one',
        () {
      const holding = Holding(card: _card, standardCopies: 1, specialCopies: 1);

      expect(holding.variantToShatter, CardVariant.standard);
    });

    test('takes a special copy when no standard one is held', () {
      const holding = Holding(card: _card, standardCopies: 0, specialCopies: 2);

      expect(holding.variantToShatter, CardVariant.special);
    });
  });
}
