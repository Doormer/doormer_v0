import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/collection.dart';
import '../../domain/entity/deck_progress.dart';
import '../../domain/usecase/load_friend_collection_usecase.dart';
import '../../domain/usecase/load_friend_decks_usecase.dart';

part 'friend_collection_event.dart';
part 'friend_collection_state.dart';

/// A friend's collection, read-only: their decks, and the cards of the one
/// open. There are no quarks, draws or shatters here.
///
/// A 404 means the two aren't friends any more, and the page leaves.
class FriendCollectionBloc
    extends Bloc<FriendCollectionEvent, FriendCollectionState> {
  final LoadFriendDecksUseCase loadDecks;
  final LoadFriendCollectionUseCase loadCollection;

  FriendCollectionBloc({
    required this.loadDecks,
    required this.loadCollection,
  }) : super(const FriendCollectionLoading()) {
    on<FriendCollectionStarted>(_onStarted);
    on<FriendDeckSelected>(_onDeckSelected);
    on<FriendDeckClosed>(_onDeckClosed);
  }

  Future<void> _onStarted(
    FriendCollectionStarted event,
    Emitter<FriendCollectionState> emit,
  ) async {
    final friend = event.friend;
    emit(FriendCollectionLoading(friend: friend));
    try {
      final read = await loadDecks(event.friendId);
      emit(FriendCollectionReady(friend: read.friend, decks: read.decks));
    } catch (e, stackTrace) {
      if (_isGone(e)) {
        emit(const FriendCollectionGone());
        return;
      }
      emit(FriendCollectionError(
        friend: friend,
        message: _messageFor(e, stackTrace, nickname: friend?.nickname),
      ));
    }
  }

  Future<void> _onDeckSelected(
    FriendDeckSelected event,
    Emitter<FriendCollectionState> emit,
  ) async {
    final ready = state;
    if (ready is! FriendCollectionReady) return;
    emit(FriendCollectionReady(
      friend: ready.friend,
      decks: ready.decks,
      selectedDeckId: event.deckId,
    ));

    try {
      final read = await loadCollection(ready.friend.friendId, event.deckId);
      final latest = state;
      if (latest is! FriendCollectionReady ||
          latest.selectedDeckId != event.deckId) {
        return;
      }
      emit(FriendCollectionReady(
        friend: read.friend,
        decks: latest.decks,
        selectedDeckId: event.deckId,
        collection: read.collection,
      ));
    } catch (e, stackTrace) {
      if (_isGone(e)) {
        emit(const FriendCollectionGone());
        return;
      }
      final latest = state;
      if (latest is! FriendCollectionReady ||
          latest.selectedDeckId != event.deckId) {
        return;
      }
      emit(FriendCollectionReady(
        friend: latest.friend,
        decks: latest.decks,
        selectedDeckId: event.deckId,
        deckErrorMessage: _messageFor(
          e,
          stackTrace,
          nickname: latest.friend.nickname,
        ),
      ));
    }
  }

  void _onDeckClosed(
    FriendDeckClosed event,
    Emitter<FriendCollectionState> emit,
  ) {
    final ready = state;
    if (ready is! FriendCollectionReady) return;
    emit(FriendCollectionReady(friend: ready.friend, decks: ready.decks));
  }

  /// Not friends any more.
  static bool _isGone(Object error) =>
      error is RefusedFailure && error.statusCode == 404;

  /// A refusal, such as friends being turned off, says what it is. Anything
  /// else says the friend's cards couldn't load.
  static String _messageFor(
    Object error,
    StackTrace stackTrace, {
    required String? nickname,
  }) {
    AppLogger.error("A friend's collection failed to load",
        error: error, stackTrace: stackTrace);
    if (error is RefusedFailure) return error.message;
    return FriendsMessages.couldNotLoadCardsOf(nickname);
  }
}
