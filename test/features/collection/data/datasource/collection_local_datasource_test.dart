import 'package:doormer/src/features/collection/data/datasource/collection_local_datasource.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
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
    expect(sequence.first.card.id, 'quadrant');
    expect(sequence.first.kind, DrawResultKind.newCard);
    expect(sequence[1].kind, DrawResultKind.duplicate);
  });

  test('every art asset named in the collection actually exists', () async {
    final collection = await dataSource.loadCollection();
    for (final deck in collection.decks) {
      for (final card in deck.cards) {
        // Throws if the asset is missing from the bundle.
        await rootBundle.load(card.artAsset);
      }
    }
  });
}
