import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/collection.dart';
import 'package:doormer/src/features/collection/domain/entity/deck.dart';
import 'package:doormer/src/features/collection/domain/entity/deck_progress.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/domain/repository/friend_collection_repository.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_friend_collection_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_friend_decks_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/friend_collection_bloc.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

const _sam = FriendSummary(friendId: '42', nickname: 'Sam');
const _meridian = DeckProgress(
  deckId: 'meridian-01',
  name: 'Meridian',
  cardsHeld: 1,
  cardsTotal: 2,
);
const _gnomon = CollectibleCard(
  id: 'gnomon',
  name: 'Gnomon',
  rarity: Rarity.common,
  scaleLabel: 'Small',
  artUrl: 'https://example.test/gnomon.png',
  standardShatterQuarks: 0,
  specialShatterQuarks: 0,
  description: 'd',
);
const _collection = Collection(
  deck:
      Deck(id: 'meridian-01', name: 'Meridian', drawCost: 0, cards: [_gnomon]),
  holdingsByCardId: {
    'gnomon': Holding(card: _gnomon, standardCopies: 2, specialCopies: 0),
  },
);

/// Sam's collection. A test can make the next read of either kind fail.
class _FakeRepository implements FriendCollectionRepository {
  Object? decksError;
  Object? cardsError;

  @override
  Future<({FriendSummary friend, List<DeckProgress> decks})> loadDecks(
      String friendId) async {
    final error = decksError;
    decksError = null;
    if (error != null) throw error;
    return (friend: _sam, decks: const [_meridian]);
  }

  @override
  Future<({FriendSummary friend, Collection collection})> loadCollection(
      String friendId, String deckId) async {
    final error = cardsError;
    cardsError = null;
    if (error != null) throw error;
    return (friend: _sam, collection: _collection);
  }
}

void main() {
  setUpAll(AppLogger.disable);

  late _FakeRepository repository;

  setUp(() => repository = _FakeRepository());

  FriendCollectionBloc build() => FriendCollectionBloc(
        loadDecks: LoadFriendDecksUseCase(repository),
        loadCollection: LoadFriendCollectionUseCase(repository),
      );

  const decks = FriendCollectionReady(friend: _sam, decks: [_meridian]);

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    'shows the friend at once, then their decks',
    build: build,
    act: (bloc) => bloc.add(
      const FriendCollectionStarted(friendId: '42', friend: _sam),
    ),
    expect: () => [const FriendCollectionLoading(friend: _sam), decks],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    'opens a deck: its cards load, then show',
    build: build,
    seed: () => decks,
    act: (bloc) => bloc.add(const FriendDeckSelected('meridian-01')),
    expect: () => [
      const FriendCollectionReady(
        friend: _sam,
        decks: [_meridian],
        selectedDeckId: 'meridian-01',
      ),
      const FriendCollectionReady(
        friend: _sam,
        decks: [_meridian],
        selectedDeckId: 'meridian-01',
        collection: _collection,
      ),
    ],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    'closing the deck goes back to the decks',
    build: build,
    seed: () => const FriendCollectionReady(
      friend: _sam,
      decks: [_meridian],
      selectedDeckId: 'meridian-01',
      collection: _collection,
    ),
    act: (bloc) => bloc.add(const FriendDeckClosed()),
    expect: () => [decks],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    'not friends any more leaves',
    build: build,
    setUp: () => repository.decksError =
        RefusedFailure(404, "We couldn't find that friend."),
    act: (bloc) => bloc.add(const FriendCollectionStarted(friendId: '42')),
    expect: () => [
      const FriendCollectionLoading(),
      const FriendCollectionGone(),
    ],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    "a deck that answers 404 leaves too: they aren't friends any more",
    build: build,
    seed: () => decks,
    setUp: () => repository.cardsError =
        RefusedFailure(404, "We couldn't find that friend."),
    act: (bloc) => bloc.add(const FriendDeckSelected('meridian-01')),
    skip: 1,
    expect: () => [const FriendCollectionGone()],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    "a load that fails says the friend's cards couldn't load",
    build: build,
    setUp: () => repository.decksError =
        NetworkFailure("We couldn't load your friend's cards."),
    act: (bloc) => bloc.add(
      const FriendCollectionStarted(friendId: '42', friend: _sam),
    ),
    expect: () => [
      const FriendCollectionLoading(friend: _sam),
      const FriendCollectionError(
        friend: _sam,
        message: "We couldn't load Sam's cards.",
      ),
    ],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    'with friends turned off, says so',
    build: build,
    setUp: () => repository.decksError =
        RefusedFailure(403, 'Friends is turned off for your account.'),
    act: (bloc) => bloc.add(const FriendCollectionStarted(friendId: '42')),
    expect: () => [
      const FriendCollectionLoading(),
      const FriendCollectionError(
          message: 'Friends is turned off for your account.'),
    ],
  );

  blocTest<FriendCollectionBloc, FriendCollectionState>(
    'a deck that fails to load says why, in place of its cards',
    build: build,
    seed: () => decks,
    setUp: () => repository.cardsError = NetworkFailure(),
    act: (bloc) => bloc.add(const FriendDeckSelected('meridian-01')),
    skip: 1,
    expect: () => [
      const FriendCollectionReady(
        friend: _sam,
        decks: [_meridian],
        selectedDeckId: 'meridian-01',
        deckErrorMessage: "We couldn't load Sam's cards.",
      ),
    ],
  );
}
