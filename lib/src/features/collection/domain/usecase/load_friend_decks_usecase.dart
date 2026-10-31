import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../entity/deck_progress.dart';
import '../repository/friend_collection_repository.dart';

class LoadFriendDecksUseCase {
  final FriendCollectionRepository repository;

  const LoadFriendDecksUseCase(this.repository);

  Future<({FriendSummary friend, List<DeckProgress> decks})> call(
    String friendId,
  ) =>
      repository.loadDecks(friendId);
}
