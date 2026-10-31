import 'package:doormer/src/shared/friends/entity/friend_summary.dart';

import '../entity/collection.dart';
import '../entity/deck_progress.dart';

/// A friend's collection, read-only: their decks and cards, without quarks,
/// draws or shatters. Reading it changes nothing.
///
/// Every method throws a `Failure` whose message a student can read. Not
/// being friends any more is a `RefusedFailure` with status 404.
abstract class FriendCollectionRepository {
  Future<({FriendSummary friend, List<DeckProgress> decks})> loadDecks(
    String friendId,
  );

  /// One of the friend's decks, with every card in it, held or not.
  Future<({FriendSummary friend, Collection collection})> loadCollection(
    String friendId,
    String deckId,
  );
}
