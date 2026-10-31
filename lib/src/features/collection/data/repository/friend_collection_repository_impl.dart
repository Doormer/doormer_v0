import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../../domain/entity/collection.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/repository/friend_collection_repository.dart';
import '../datasource/friend_collection_remote_datasource.dart';

/// Turns the API's answers into the domain's terms. Failures pass straight
/// through.
class FriendCollectionRepositoryImpl implements FriendCollectionRepository {
  final FriendCollectionRemoteDataSource remoteDataSource;

  const FriendCollectionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<({FriendSummary friend, List<DeckProgress> decks})> loadDecks(
    String friendId,
  ) async {
    final response = await remoteDataSource.decks(friendId);
    return (
      friend: response.friend.toEntity(),
      decks: [for (final deck in response.decks) deck.toEntity()],
    );
  }

  @override
  Future<({FriendSummary friend, Collection collection})> loadCollection(
    String friendId,
    String deckId,
  ) async {
    final response = await remoteDataSource.cards(friendId, deckId);
    return (
      friend: response.friend.toEntity(),
      collection: response.toEntity()
    );
  }
}
