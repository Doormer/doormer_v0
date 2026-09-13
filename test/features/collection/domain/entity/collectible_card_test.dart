// test/features/collection/domain/entity/collectible_card_test.dart
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rarity', () {
    test('conversion values match the verified economy', () {
      expect(Rarity.common.conversionValue, 5);
      expect(Rarity.uncommon.conversionValue, 11);
      expect(Rarity.rare.conversionValue, 19);
    });

    test('a special copy is worth exactly double a standard one', () {
      for (final r in Rarity.values) {
        expect(r.specialConversionValue, r.conversionValue * 2);
      }
    });
  });

  group('CollectibleCard', () {
    test('two cards with the same id are equal', () {
      const a = CollectibleCard(
        id: 'gnomon',
        name: 'Gnomon',
        deckId: 'meridian',
        rarity: Rarity.common,
        scaleLabel: 'Small',
        artAsset: 'assets/cards/meridian/gnomon.png',
        description: 'Casts a shadow that tells the time.',
      );
      const b = CollectibleCard(
        id: 'gnomon',
        name: 'Gnomon renamed',
        deckId: 'meridian',
        rarity: Rarity.rare,
        scaleLabel: 'Capital',
        artAsset: 'other.png',
        description: 'different',
      );
      expect(a, equals(b));
    });
  });
}
