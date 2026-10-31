part of 'friend_collection_bloc.dart';

sealed class FriendCollectionEvent extends Equatable {
  const FriendCollectionEvent();

  @override
  List<Object?> get props => const [];
}

/// The collection opened, or the student tapped Try again.
class FriendCollectionStarted extends FriendCollectionEvent {
  final String friendId;

  /// The friend as Profile showed them, so the heading needn't wait. Null
  /// when the collection was opened by its address.
  final FriendSummary? friend;

  const FriendCollectionStarted({required this.friendId, this.friend});

  @override
  List<Object?> get props => [friendId, friend];
}

class FriendDeckSelected extends FriendCollectionEvent {
  final String deckId;

  const FriendDeckSelected(this.deckId);

  @override
  List<Object?> get props => [deckId];
}

/// Leaves the open deck for the deck list.
class FriendDeckClosed extends FriendCollectionEvent {
  const FriendDeckClosed();
}
