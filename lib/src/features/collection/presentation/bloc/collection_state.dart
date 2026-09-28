// lib/src/features/collection/presentation/bloc/collection_state.dart
part of 'collection_bloc.dart';

sealed class CollectionState extends Equatable {
  const CollectionState();

  @override
  List<Object?> get props => const [];
}

/// The first read of the deck list.
class CollectionLoading extends CollectionState {
  const CollectionLoading();
}

/// The first read of the deck list failed.
class CollectionError extends CollectionState {
  final String message;
  const CollectionError(this.message);

  @override
  List<Object?> get props => [message];
}

class CollectionReady extends CollectionState {
  final int quarkBalance;
  final List<DeckProgress> decks;

  /// Null means the deck list is showing. On a phone that is a screen of its
  /// own; on desktop the rail is always present and this is which row is open.
  final String? selectedDeckId;

  /// The open deck. Null while it loads, or after reading it failed.
  final Collection? collection;

  /// Why the open deck could not load.
  final String? deckErrorMessage;

  /// Set for exactly as long as a reveal is on screen.
  final PendingReveal? pendingReveal;

  final bool isDrawing;
  final bool isShattering;

  /// Set once when an action fails, so the page can toast it. Cleared by the
  /// next change of state.
  final String? errorMessage;

  const CollectionReady({
    required this.quarkBalance,
    required this.decks,
    this.selectedDeckId,
    this.collection,
    this.deckErrorMessage,
    this.pendingReveal,
    this.isDrawing = false,
    this.isShattering = false,
    this.errorMessage,
  });

  CollectionReady copyWith({
    int? quarkBalance,
    List<DeckProgress>? decks,
    String? selectedDeckId,
    bool clearSelectedDeck = false,
    Collection? collection,
    bool clearCollection = false,
    String? deckErrorMessage,
    bool clearDeckError = false,
    PendingReveal? pendingReveal,
    bool clearReveal = false,
    bool? isDrawing,
    bool? isShattering,
    String? errorMessage,
  }) {
    return CollectionReady(
      quarkBalance: quarkBalance ?? this.quarkBalance,
      decks: decks ?? this.decks,
      selectedDeckId:
          clearSelectedDeck ? null : (selectedDeckId ?? this.selectedDeckId),
      collection: clearCollection ? null : (collection ?? this.collection),
      deckErrorMessage:
          clearDeckError ? null : (deckErrorMessage ?? this.deckErrorMessage),
      pendingReveal: clearReveal ? null : (pendingReveal ?? this.pendingReveal),
      isDrawing: isDrawing ?? this.isDrawing,
      isShattering: isShattering ?? this.isShattering,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        quarkBalance,
        decks,
        selectedDeckId,
        collection,
        deckErrorMessage,
        pendingReveal,
        isDrawing,
        isShattering,
        errorMessage,
      ];
}

/// A draw waiting to be revealed, with what the reveal needs to describe it.
class PendingReveal extends Equatable {
  final DrawOutcome outcome;

  /// The drawn deck's name. The student may have opened another deck by the
  /// time the reveal plays.
  final String deckName;

  /// The drawn deck after the draw. Null when reading it failed.
  final Collection? collectionAfterDraw;

  const PendingReveal({
    required this.outcome,
    required this.deckName,
    this.collectionAfterDraw,
  });

  @override
  List<Object?> get props => [outcome, deckName, collectionAfterDraw];
}
