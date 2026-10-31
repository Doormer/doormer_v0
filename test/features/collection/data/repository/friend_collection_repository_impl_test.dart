import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/collection/data/datasource/friend_collection_remote_datasource.dart';
import 'package:doormer/src/features/collection/data/model/collection_response_models.dart';
import 'package:doormer/src/features/collection/data/repository/friend_collection_repository_impl.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _sam = FriendSummaryModel(friendId: '42', nickname: 'Sam');

class _FakeRemoteDataSource implements FriendCollectionRemoteDataSource {
  Failure? failure;
  final List<String> calls = [];

  @override
  Future<FriendDecksResponseModel> decks(String friendId) async {
    calls.add('decks $friendId');
    final failure = this.failure;
    if (failure != null) throw failure;
    return const FriendDecksResponseModel(friend: _sam, decks: [
      DeckProgressModel(
        deckId: 'meridian-01',
        name: 'Meridian',
        cardsHeld: 1,
        cardsTotal: 6,
      ),
    ]);
  }

  @override
  Future<FriendCardsResponseModel> cards(String friendId, String deckId) async {
    calls.add('cards $friendId $deckId');
    return const FriendCardsResponseModel(
      friend: _sam,
      deckId: 'meridian-01',
      deckName: 'Meridian',
      cards: [
        FriendHeldCardModel(
          cardId: 'gnomon',
          name: 'Gnomon',
          rarity: Rarity.common,
          artUrl: 'https://example.test/gnomon.png',
          scaleLabel: 'Small',
          description: 'd',
          standardCopies: 1,
          specialCopies: 0,
        ),
      ],
    );
  }
}

void main() {
  late _FakeRemoteDataSource remote;
  late FriendCollectionRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemoteDataSource();
    repository = FriendCollectionRepositoryImpl(remoteDataSource: remote);
  });

  test("the friend's decks come back in the domain's terms", () async {
    final read = await repository.loadDecks('42');

    expect(read.friend, const FriendSummary(friendId: '42', nickname: 'Sam'));
    expect(read.decks.single.cardsHeld, 1);
    expect(remote.calls, ['decks 42']);
  });

  test("a friend's deck comes back as a collection with nothing to shatter",
      () async {
    final read = await repository.loadCollection('42', 'meridian-01');

    expect(read.collection.holdings.single.card.name, 'Gnomon');
    expect(read.collection.holdings.single.card.standardShatterQuarks, 0);
    expect(remote.calls, ['cards 42 meridian-01']);
  });

  test('a failure reaches the caller unchanged', () async {
    final failure = RefusedFailure(404, "We couldn't find that friend.");
    remote.failure = failure;

    await expectLater(repository.loadDecks('42'), throwsA(same(failure)));
  });
}
