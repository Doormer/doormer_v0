import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/collection/data/datasource/collection_local_datasource.dart';
import 'package:doormer/src/features/collection/data/repository/collection_repository_impl.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  deckId: 'meridian',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/a.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'd',
);
const _quadrant = CollectibleCard(
  id: 'quadrant',
  name: 'Quadrant',
  deckId: 'meridian',
  rarity: Rarity.uncommon,
  scaleLabel: 'Medium',
  artUrl: 'https://example.test/b.jpg',
  standardShatterQuarks: 11,
  specialShatterQuarks: 22,
  description: 'd',
);
const _flint = CollectibleCard(
  id: 'flint',
  name: 'Flint',
  deckId: 'cinder',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/c.jpg',
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
  description: 'd',
);

/// Hand-written fake, matching the repo's existing test style. `mockito` is in
/// `pubspec.yaml` but no test in this repo uses it.
class _FakeDataSource implements CollectionLocalDataSource {
  final List<DrawOutcome> sequence;
  _FakeDataSource(this.sequence);

  @override
  Future<Collection> loadCollection() async => const Collection(
        decks: [
          Deck(id: 'meridian', name: 'Meridian', cards: [_gnomon, _quadrant]),
          Deck(id: 'cinder', name: 'Cinder', cards: [_flint]),
        ],
        holdingsByCardId: {
          'gnomon': Holding(
            card: _gnomon,
            standardCopies: 2,
            specialCopies: 0,
          ),
        },
        quarkBalance: 80,
        drawCost: 40,
      );

  @override
  Future<List<DrawOutcome>> loadDrawSequence() async => sequence;
}

CollectionRepositoryImpl _repo(List<DrawOutcome> sequence) {
  return CollectionRepositoryImpl(dataSource: _FakeDataSource(sequence));
}

void main() {
  test('a new card appears in the collection and costs the draw price',
      () async {
    final repo = _repo(const [
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    final outcome = await repo.draw('meridian');
    final after = await repo.current();

    expect(outcome.result, DrawResult.newCard);
    expect(outcome.copiesAfter, 1);
    expect(after.holdingsByCardId.containsKey('quadrant'), isTrue);
    expect(after.quarkBalance, 40);
  });

  test('a duplicate raises the count and reports it', () async {
    final repo = _repo(const [
      DrawOutcome(
        card: _gnomon,
        variant: CardVariant.standard,
        result: DrawResult.duplicate,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    final outcome = await repo.draw('meridian');

    expect(outcome.copiesAfter, 3);
    expect(
        (await repo.current()).holdingsByCardId['gnomon']!.standardCopies, 3);
  });

  test('an upgrade adds a special copy and keeps the standard one', () async {
    final repo = _repo(const [
      DrawOutcome(
        card: _gnomon,
        variant: CardVariant.special,
        result: DrawResult.upgrade,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    await repo.draw('meridian');
    final holding = (await repo.current()).holdingsByCardId['gnomon']!;

    expect(holding.standardCopies, 2, reason: 'the standard copy is kept');
    expect(holding.specialCopies, 1);
    expect(holding.totalCopies, 3);
  });

  test('drawing without enough quarks fails and changes nothing', () async {
    final repo = _repo(const [
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.duplicate,
        copiesAfter: 0,
      ),
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.duplicate,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    await repo.draw('meridian'); // 80 -> 40
    await repo.draw('meridian'); // 40 -> 0

    expect(() => repo.draw('meridian'), throwsA(isA<ValidationFailure>()));
    expect((await repo.current()).quarkBalance, 0);
  });

  test('the sequence wraps so review never runs dry', () async {
    final repo = _repo(const [
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    final first = await repo.draw('meridian');
    // Top the wallet back up by shattering, so a second draw is affordable.
    await repo.shatterCopy('gnomon', CardVariant.standard);
    await repo.shatterCopy('gnomon', CardVariant.standard);
    final second = await repo.draw('meridian');

    expect(first.card.id, 'quadrant');
    expect(second.card.id, 'quadrant', reason: 'sequence restarts at the top');
  });

  test('shattering pays the rarity value and removes exactly one copy',
      () async {
    final repo = _repo(const []);
    await repo.load();

    final after = await repo.shatterCopy('gnomon', CardVariant.standard);

    expect(after.quarkBalance, 85, reason: '80 + 5 for a common');
    expect(after.holdingsByCardId['gnomon']!.standardCopies, 1);
  });

  test('shattering the last copy removes the holding entirely', () async {
    final repo = _repo(const []);
    await repo.load();

    await repo.shatterCopy('gnomon', CardVariant.standard);
    final after = await repo.shatterCopy('gnomon', CardVariant.standard);

    expect(after.holdingsByCardId.containsKey('gnomon'), isFalse);
  });

  test('shattering a copy that is not held fails', () async {
    final repo = _repo(const []);
    await repo.load();

    expect(
      () => repo.shatterCopy('gnomon', CardVariant.special),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('a draw never awards a card from another deck', () async {
    // The bundled asset interleaves decks; a shared cursor would leak one
    // deck's card into another deck's draw.
    final repo = _repo(const [
      DrawOutcome(
        card: _flint, // cinder
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
      DrawOutcome(
        card: _quadrant, // meridian
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    final outcome = await repo.draw('meridian');

    expect(outcome.card.deckId, 'meridian');
    expect(outcome.card.id, 'quadrant');
  });

  test('each deck keeps its own place in the sequence', () async {
    final repo = _repo(const [
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
      DrawOutcome(
        card: _flint,
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    final first = await repo.draw('meridian');
    final second = await repo.draw('cinder');

    expect(first.card.id, 'quadrant');
    expect(second.card.id, 'flint');
  });

  test('a repeated card stops claiming to be new', () async {
    // Second lap of a one-step sequence: the asset still says newCard, but the
    // card is held by then.
    final repo = _repo(const [
      DrawOutcome(
        card: _quadrant,
        variant: CardVariant.standard,
        result: DrawResult.newCard,
        copiesAfter: 0,
      ),
    ]);
    await repo.load();

    final first = await repo.draw('meridian');
    await repo.shatterCopy('gnomon', CardVariant.standard);
    await repo.shatterCopy('gnomon', CardVariant.standard);
    final second = await repo.draw('meridian');

    expect(first.result, DrawResult.newCard);
    expect(second.result, DrawResult.duplicate);
    expect(second.copiesAfter, 2);
  });
}
