import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/collection/data/datasource/collection_remote_datasource.dart';
import 'package:doormer/src/features/collection/data/model/collection_response_models.dart';
import 'package:doormer/src/features/collection/data/repository/collection_repository_impl.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/draw_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = HeldCardModel(
  cardId: 'gnomon',
  name: 'Gnomon',
  rarity: Rarity.common,
  artUrl: 'https://example.test/gnomon.jpg',
  scaleLabel: 'Small',
  description: 'd',
  standardCopies: 2,
  specialCopies: 0,
  standardShatterQuarks: 5,
  specialShatterQuarks: 10,
);

final _noConnection =
    NetworkFailure("We couldn't connect. Check your connection and try again.");
final _serverError = ServerFailure('Something went wrong. Try again.');

/// Answers like the API, and keeps every idempotency key it is sent. Set
/// [failure] to make every call fail with it instead.
class _FakeRemoteDataSource implements CollectionRemoteDataSource {
  Failure? failure;
  final List<String> keysSent = [];
  String? shatteredWith;

  void _failIfAsked() {
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  @override
  Future<DecksResponseModel> decks() async {
    _failIfAsked();
    return const DecksResponseModel(quarkBalance: 40, decks: [
      DeckProgressModel(
        deckId: 'meridian-01',
        name: 'Meridian',
        cardsHeld: 1,
        cardsTotal: 6,
      ),
    ]);
  }

  @override
  Future<CardsResponseModel> cards(String deckId) async {
    _failIfAsked();
    return CardsResponseModel(
      quarkBalance: 40,
      deck: DeckSummaryModel(deckId: deckId, name: 'Meridian', drawCost: 40),
      cards: const [_gnomon],
    );
  }

  @override
  Future<DrawResponseModel> draw(
    String deckId, {
    required String idempotencyKey,
  }) async {
    keysSent.add(idempotencyKey);
    _failIfAsked();
    return const DrawResponseModel(
      quarkBalance: 0,
      card: _gnomon,
      variant: CardVariant.standard,
      result: DrawResult.duplicate,
      copiesAfter: 3,
    );
  }

  @override
  Future<ShatterResponseModel> shatter(
    String deckId,
    String cardId,
    CardVariant variant, {
    required String idempotencyKey,
  }) async {
    keysSent.add(idempotencyKey);
    shatteredWith = '$deckId $cardId ${variant.name}';
    _failIfAsked();
    return const ShatterResponseModel(
      quarkBalance: 45,
      standardCopies: 1,
      specialCopies: 0,
    );
  }
}

void main() {
  late _FakeRemoteDataSource remote;
  late CollectionRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemoteDataSource();
    var keys = 0;
    repository = CollectionRepositoryImpl(
      remoteDataSource: remote,
      idempotencyKeyFactory: () => 'key-${++keys}',
    );
  });

  /// Makes the next call fail with [failure], and checks that the failure
  /// reaches the caller unchanged.
  Future<void> failOnce(
      Failure failure, Future<Object?> Function() call) async {
    remote.failure = failure;
    await expectLater(call(), throwsA(same(failure)));
    remote.failure = null;
  }

  test('the deck list comes back as progress through each deck', () async {
    final list = await repository.loadDecks();

    expect(list.quarkBalance, 40);
    expect(list.decks.single.deckId, 'meridian-01');
    expect(list.decks.single.cardsHeld, 1);
    expect(list.decks.single.cardsTotal, 6);
  });

  test('a deck comes back as the collection of that deck', () async {
    final read = await repository.loadCollection('meridian-01');

    expect(read.quarkBalance, 40);
    expect(read.collection.deck.id, 'meridian-01');
    expect(read.collection.holdingOf('gnomon')?.standardCopies, 2);
  });

  test('a draw comes back as the outcome and the balance it left', () async {
    final drawn = await repository.draw('meridian-01');

    expect(drawn.quarkBalance, 0);
    expect(drawn.outcome.card.id, 'gnomon');
    expect(drawn.outcome.result, DrawResult.duplicate);
    expect(drawn.outcome.copiesAfter, 3);
  });

  test('a shatter names the copy and comes back as the copies left', () async {
    final shattered = await repository.shatterCopy(
        'meridian-01', 'gnomon', CardVariant.standard);

    expect(remote.shatteredWith, 'meridian-01 gnomon standard');
    expect(shattered.quarkBalance, 45);
    expect(shattered.standardCopies, 1);
    expect(shattered.specialCopies, 0);
  });

  test('every draw and every shatter sends a key of its own', () async {
    await repository.draw('meridian-01');
    await repository.draw('meridian-01');
    await repository.shatterCopy('meridian-01', 'gnomon', CardVariant.standard);

    expect(remote.keysSent, ['key-1', 'key-2', 'key-3']);
  });

  test('a draw whose answer was lost sends the same key when repeated',
      () async {
    await failOnce(_noConnection, () => repository.draw('meridian-01'));
    await failOnce(_serverError, () => repository.draw('meridian-01'));
    await repository.draw('meridian-01');

    expect(remote.keysSent, ['key-1', 'key-1', 'key-1']);
  });

  test('a shatter whose answer was lost sends the same key when repeated',
      () async {
    await failOnce(
      _noConnection,
      () =>
          repository.shatterCopy('meridian-01', 'gnomon', CardVariant.standard),
    );
    await repository.shatterCopy('meridian-01', 'gnomon', CardVariant.standard);

    expect(remote.keysSent, ['key-1', 'key-1']);
  });

  test('a kept draw key is sent only for a draw on the same deck', () async {
    await failOnce(_noConnection, () => repository.draw('meridian-01'));
    await repository.draw('cinder-01');
    await repository.shatterCopy('meridian-01', 'gnomon', CardVariant.standard);
    await repository.draw('meridian-01');

    expect(remote.keysSent, ['key-1', 'key-2', 'key-3', 'key-1']);
  });

  test('a kept shatter key is sent only for the same deck, card and variant',
      () async {
    await failOnce(
      _noConnection,
      () =>
          repository.shatterCopy('meridian-01', 'gnomon', CardVariant.standard),
    );
    await repository.shatterCopy('meridian-01', 'gnomon', CardVariant.special);
    await repository.shatterCopy(
        'meridian-01', 'quadrant', CardVariant.standard);
    await repository.shatterCopy('cinder-01', 'gnomon', CardVariant.standard);
    await repository.draw('meridian-01');
    await repository.shatterCopy('meridian-01', 'gnomon', CardVariant.standard);

    expect(
      remote.keysSent,
      ['key-1', 'key-2', 'key-3', 'key-4', 'key-5', 'key-1'],
    );
  });

  test('an answer retires the kept key', () async {
    await failOnce(_noConnection, () => repository.draw('meridian-01'));
    await repository.draw('meridian-01');
    await repository.draw('meridian-01');

    expect(remote.keysSent, ['key-1', 'key-1', 'key-2']);
  });

  final definiteFailures = <String, Failure>{
    'a 409': ValidationFailure("You don't have enough quarks for a draw."),
    'a 404': ApiFailure(404, 'Something went wrong. Try again.'),
    'a 401': AuthFailure(),
    'an unreadable answer': UnknownFailure('Something went wrong. Try again.'),
  };
  definiteFailures.forEach((answer, failure) {
    test('$answer retires the kept key', () async {
      await failOnce(_noConnection, () => repository.draw('meridian-01'));
      await failOnce(failure, () => repository.draw('meridian-01'));
      await repository.draw('meridian-01');

      expect(remote.keysSent, ['key-1', 'key-1', 'key-2']);
    });
  });

  test('a failure reaches the caller unchanged', () async {
    final refused =
        ValidationFailure("You don't have enough quarks for a draw.");
    remote.failure = refused;

    await expectLater(repository.draw('meridian-01'), throwsA(same(refused)));
    await expectLater(repository.loadDecks(), throwsA(same(refused)));
  });

  group('the last deck list', () {
    test('is nothing before the first read', () {
      expect(repository.lastDeckList, isNull);
    });

    test('is the deck list as it was read', () async {
      await repository.loadDecks();

      expect(repository.lastDeckList?.quarkBalance, 40);
      expect(repository.lastDeckList?.decks.single.deckId, 'meridian-01');
    });

    test('takes the balance of every later answer, and keeps its decks',
        () async {
      final decks = (await repository.loadDecks()).decks;

      await repository.draw('meridian-01');
      expect(repository.lastDeckList?.quarkBalance, 0, reason: 'a draw');

      await repository.loadCollection('meridian-01');
      expect(repository.lastDeckList?.quarkBalance, 40,
          reason: 'opening a deck');

      await repository.shatterCopy(
          'meridian-01', 'gnomon', CardVariant.standard);
      expect(repository.lastDeckList?.quarkBalance, 45, reason: 'a shatter');

      expect(repository.lastDeckList?.decks, same(decks),
          reason: 'only reading the deck list changes the decks');
    });

    test('stays as it was when a call fails', () async {
      await repository.loadDecks();

      await failOnce(_noConnection, repository.loadDecks);
      await failOnce(_noConnection, () => repository.draw('meridian-01'));

      expect(repository.lastDeckList?.quarkBalance, 40);
    });

    test('is forgotten, and later answers do not bring it back', () async {
      await repository.loadDecks();

      repository.forgetLastDeckList();
      await repository.draw('meridian-01');

      expect(repository.lastDeckList, isNull);
    });
  });
}
