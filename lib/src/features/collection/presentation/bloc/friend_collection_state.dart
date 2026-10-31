part of 'friend_collection_bloc.dart';

sealed class FriendCollectionState extends Equatable {
  const FriendCollectionState();

  @override
  List<Object?> get props => const [];
}

/// The deck list is on its way.
class FriendCollectionLoading extends FriendCollectionState {
  /// Null until the friend is known.
  final FriendSummary? friend;

  const FriendCollectionLoading({this.friend});

  @override
  List<Object?> get props => [friend];
}

/// The deck list could not load.
class FriendCollectionError extends FriendCollectionState {
  final FriendSummary? friend;
  final String message;

  const FriendCollectionError({this.friend, required this.message});

  @override
  List<Object?> get props => [friend, message];
}

/// The two aren't friends any more.
class FriendCollectionGone extends FriendCollectionState {
  const FriendCollectionGone();
}

class FriendCollectionReady extends FriendCollectionState {
  final FriendSummary friend;
  final List<DeckProgress> decks;

  /// Null while the deck list shows.
  final String? selectedDeckId;

  /// The open deck. Null while it loads, or after reading it failed.
  final Collection? collection;

  /// Why the open deck could not load.
  final String? deckErrorMessage;

  const FriendCollectionReady({
    required this.friend,
    required this.decks,
    this.selectedDeckId,
    this.collection,
    this.deckErrorMessage,
  });

  @override
  List<Object?> get props =>
      [friend, decks, selectedDeckId, collection, deckErrorMessage];
}
