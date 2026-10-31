import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../entity/collection.dart';
import '../repository/friend_collection_repository.dart';

class LoadFriendCollectionUseCase {
  final FriendCollectionRepository repository;

  const LoadFriendCollectionUseCase(this.repository);

  Future<({FriendSummary friend, Collection collection})> call(
    String friendId,
    String deckId,
  ) =>
      repository.loadCollection(friendId, deckId);
}
