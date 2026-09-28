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

  test('a failure reaches the caller unchanged', () async {
    final refused =
        ValidationFailure("You don't have enough quarks for a draw.");
    remote.failure = refused;

    await expectLater(repository.draw('meridian-01'), throwsA(same(refused)));
    await expectLater(repository.loadDecks(), throwsA(same(refused)));
  });
}
