import 'package:doormer/src/features/collection/data/datasource/collection_local_datasource.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CollectionLocalDataSourceImpl dataSource;

  setUp(() {
    dataSource = CollectionLocalDataSourceImpl(bundle: rootBundle);
  });

  test('loads two decks with six cards each', () async {
    final collection = await dataSource.loadCollection();
    expect(collection.decks.length, 2);
    for (final deck in collection.decks) {
      expect(deck.size, 6, reason: '${deck.name} should have six cards');
    }
  });

  test('every deck has exactly one rare', () async {
    final collection = await dataSource.loadCollection();
    for (final deck in collection.decks) {
      expect(deck.rarityMix[Rarity.rare], 1, reason: deck.name);
    }
  });

  test('holdings are keyed by card id and carry both printings', () async {
    final collection = await dataSource.loadCollection();
    expect(collection.holdingsByCardId['gnomon']!.totalCopies, 3);
    expect(collection.holdingsByCardId['astrolabe']!.hasSpecial, isTrue);
    expect(collection.holdingsByCardId.containsKey('quadrant'), isFalse);
  });

  test('cinder is held nothing from, which is the empty deck case', () async {
    final collection = await dataSource.loadCollection();
    expect(collection.heldCountFor('cinder'), 0);
  });

  test('the draw sequence resolves card ids to real cards', () async {
    final sequence = await dataSource.loadDrawSequence();
    expect(sequence, isNotEmpty);
    // The fixture deliberately opens each deck on its rare, so a reviewer sees
    // the flourish on the first draw rather than three draws later.
    expect(sequence.first.card.id, 'orrery');
    expect(sequence.first.card.rarity, Rarity.rare);
    expect(sequence.first.variant, CardVariant.special);
    // Every step must name a card that exists; a typo here is a crash at draw.
    expect(sequence.every((s) => s.card.id.isNotEmpty), isTrue);
  });

  test('every card has its art on the server and its shatter values', () async {
    final collection = await dataSource.loadCollection();
    const standard = {Rarity.common: 5, Rarity.uncommon: 11, Rarity.rare: 19};
    for (final deck in collection.decks) {
      for (final card in deck.cards) {
        expect(
          card.artUrl,
          'https://takadev1cv.blob.core.windows.net/card-art/'
          '${deck.id}-01/${card.id}.jpg',
        );
        expect(card.standardShatterQuarks, standard[card.rarity],
            reason: card.id);
        expect(card.specialShatterQuarks, standard[card.rarity]! * 2,
            reason: card.id);
      }
    }
  });
}
