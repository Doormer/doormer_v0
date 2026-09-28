// test/features/collection/domain/entity/collectible_card_test.dart
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  deckId: 'meridian',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/gnomon.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'Casts a shadow that tells the time.',
);

void main() {
  test('two cards with the same id are equal', () {
    const renamed = CollectibleCard(
      id: 'gnomon',
      name: 'Gnomon renamed',
      deckId: 'meridian',
      rarity: Rarity.rare,
      scaleLabel: 'Capital',
      artUrl: 'https://example.test/other.jpg',
      standardShatterQuarks: 19,
      specialShatterQuarks: 38,
      description: 'different',
    );
    expect(_gnomon, equals(renamed));
  });

  test('shatterQuarksFor gives the value for the printing asked about', () {
    expect(_gnomon.shatterQuarksFor(CardVariant.standard), 5);
    expect(_gnomon.shatterQuarksFor(CardVariant.special), 10);
  });
}
