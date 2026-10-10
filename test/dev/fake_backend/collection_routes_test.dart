import 'dart:math';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/collection/data/datasource/collection_remote_datasource.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays a draw's rolls from a script: [doubles] decide the variant, then
/// the rarity; [ints] pick the card within that rarity.
class _ScriptedRandom implements Random {
  final List<double> doubles;
  final List<int> ints;
  var _doublesUsed = 0;
  var _intsUsed = 0;

  _ScriptedRandom({required this.doubles, required this.ints});

  @override
  double nextDouble() => doubles[_doublesUsed++];

  @override
  int nextInt(int max) => ints[_intsUsed++];

  @override
  bool nextBool() => throw UnimplementedError();
}

CollectionRemoteDataSource _collection(Random random) =>
    CollectionRemoteDataSourceImpl(
      dio: Dio(BaseOptions(
        baseUrl: 'https://api.test',
        headers: {'Authorization': 'Bearer test-token'},
      ))
        ..httpClientAdapter = fakeBackend(
          delay: Duration.zero,
          solveDelay: Duration.zero,
          random: random,
        ),
    );

void main() {
  setUpAll(AppLogger.disable);

  late CollectionRemoteDataSource collection;
  var keysUsed = 0;
  String newKey() => 'key-${keysUsed++}';

  setUp(() => collection = _collection(Random(1)));

  test('starts with 200 quarks and three Meridian cards held', () async {
    final decks = await collection.decks();

    expect(decks.quarkBalance, 200);
    expect(
      [
        for (final deck in decks.decks)
          (deck.name, deck.cardsHeld, deck.cardsTotal)
      ],
      [('Cinder', 0, 6), ('Meridian', 3, 6)],
    );
  });

  test('a deck lists all six cards, with the copies held', () async {
    final cards = await collection.cards('meridian-01');
    final holdings = cards.toEntity().holdingsByCardId;
    final gnomon = cards.cards.firstWhere((card) => card.cardId == 'gnomon');

    expect(cards.deck.drawCost, 40);
    expect(cards.cards, hasLength(6));
    expect(holdings.keys, unorderedEquals(['gnomon', 'vernier', 'astrolabe']));
    expect(holdings['vernier']?.specialCopies, 1);
    expect(
        (gnomon.standardShatterQuarks, gnomon.specialShatterQuarks), (5, 10));
  });

  test('a draw costs 40 quarks, and the deck list and cards show it', () async {
    final drawn =
        await collection.draw('meridian-01', idempotencyKey: newKey());

    expect(drawn.quarkBalance, 160);
    expect((await collection.decks()).quarkBalance, 160);
    expect((await collection.cards('meridian-01')).quarkBalance, 160);
  });

  test('the first draw from a deck with nothing held is a new card', () async {
    final drawn = await collection.draw('cinder-01', idempotencyKey: newKey());
    final cinder = (await collection.decks())
        .decks
        .firstWhere((deck) => deck.deckId == 'cinder-01');

    expect(drawn.result, DrawResult.newCard);
    expect(drawn.copiesAfter, 1);
    expect(cinder.cardsHeld, 1);
  });

  test('a draw is refused once the quarks run out', () async {
    for (var draw = 0; draw < 5; draw++) {
      await collection.draw('meridian-01', idempotencyKey: newKey());
    }

    await expectLater(
      collection.draw('meridian-01', idempotencyKey: newKey()),
      throwsA(isA<ValidationFailure>().having((f) => f.message, 'message',
          "You don't have enough quarks for a draw.")),
    );
    expect((await collection.decks()).quarkBalance, 0);
  });

  test('a draw sent again with the same key is charged once', () async {
    final key = newKey();

    final first = await collection.draw('meridian-01', idempotencyKey: key);
    final again = await collection.draw('meridian-01', idempotencyKey: key);

    expect(again.card.cardId, first.card.cardId);
    expect((await collection.decks()).quarkBalance, 160);
  });

  test('shattering a spare copy earns its quarks', () async {
    final shattered = await collection.shatter(
        'meridian-01', 'gnomon', CardVariant.standard,
        idempotencyKey: newKey());

    expect(
      (
        shattered.quarkBalance,
        shattered.standardCopies,
        shattered.specialCopies
      ),
      (205, 1, 0),
    );
  });

  test('the last copy of a card is never shattered', () async {
    await expectLater(
      collection.shatter('meridian-01', 'astrolabe', CardVariant.standard,
          idempotencyKey: newKey()),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('an unknown deck is an error', () async {
    await expectLater(
        collection.cards('no-such-deck'), throwsA(isA<Failure>()));
  });

  group('by taka-api\'s rules', () {
    // A special common draw from Meridian, picking the card at [index] among
    // Gnomon, Vernier and Lodestone.
    Random specialCommon(int index) =>
        _ScriptedRandom(doubles: [0.1, 0.0], ints: [index]);

    test('a first special copy of a held card is an upgrade', () async {
      final drawn = await _collection(specialCommon(0))
          .draw('meridian-01', idempotencyKey: newKey());

      expect(drawn.card.cardId, 'gnomon');
      expect(drawn.variant, CardVariant.special);
      expect(drawn.result, DrawResult.upgrade);
      expect(drawn.copiesAfter, 3);
    });

    test('another special copy is a duplicate', () async {
      final drawn = await _collection(specialCommon(1))
          .draw('meridian-01', idempotencyKey: newKey());

      expect(drawn.card.cardId, 'vernier');
      expect(drawn.result, DrawResult.duplicate);
      expect(drawn.copiesAfter, 3);
    });

    test('a special copy shatters for twice a standard one', () async {
      final shattered = await collection.shatter(
          'meridian-01', 'vernier', CardVariant.special,
          idempotencyKey: newKey());

      expect(
        (
          shattered.quarkBalance,
          shattered.standardCopies,
          shattered.specialCopies
        ),
        (210, 1, 0),
      );
    });

    test('a variant not held cannot be shattered', () async {
      await expectLater(
        collection.shatter('meridian-01', 'gnomon', CardVariant.special,
            idempotencyKey: newKey()),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('a draw from an unknown deck is an error, and costs nothing',
        () async {
      await expectLater(
        collection.draw('no-such-deck', idempotencyKey: newKey()),
        throwsA(isA<Failure>()),
      );
      expect((await collection.decks()).quarkBalance, 200);
    });
  });
}
