// lib/src/features/collection/presentation/bloc/collection_state.dart
part of 'collection_bloc.dart';

sealed class CollectionState extends Equatable {
  const CollectionState();

  @override
  List<Object?> get props => const [];
}

class CollectionLoading extends CollectionState {
  const CollectionLoading();
}

class CollectionFailed extends CollectionState {
  final String message;
  const CollectionFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class CollectionReady extends CollectionState {
  final Collection collection;

  /// Null means the deck list is showing. On a phone that is a screen of its
  /// own; on desktop the rail is always present and this is which row is open.
  final String? selectedDeckId;

  /// Set for exactly as long as a reveal is on screen.
  final DrawOutcome? pendingReveal;

  final bool isDrawing;

  /// Set once when something fails, so the page can toast it. Cleared by the
  /// next successful action.
  final String? errorMessage;

  const CollectionReady({
    required this.collection,
    this.selectedDeckId,
    this.pendingReveal,
    this.isDrawing = false,
    this.errorMessage,
  });

  CollectionReady copyWith({
    Collection? collection,
    String? selectedDeckId,
    bool clearSelectedDeck = false,
    DrawOutcome? pendingReveal,
    bool clearReveal = false,
    bool? isDrawing,
    String? errorMessage,
    bool clearError = true,
  }) {
    return CollectionReady(
      collection: collection ?? this.collection,
      selectedDeckId:
          clearSelectedDeck ? null : (selectedDeckId ?? this.selectedDeckId),
      pendingReveal: clearReveal ? null : (pendingReveal ?? this.pendingReveal),
      isDrawing: isDrawing ?? this.isDrawing,
      errorMessage: errorMessage ?? (clearError ? null : this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [collection, selectedDeckId, pendingReveal, isDrawing, errorMessage];
}
