// lib/src/features/collection/presentation/bloc/collection_event.dart
part of 'collection_bloc.dart';

sealed class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => const [];
}

class CollectionStarted extends CollectionEvent {
  const CollectionStarted();
}

class DeckSelected extends CollectionEvent {
  final String deckId;
  const DeckSelected(this.deckId);

  @override
  List<Object?> get props => [deckId];
}

/// Leaves the open deck and returns to the list.
class DeckClosed extends CollectionEvent {
  const DeckClosed();
}

class DrawRequested extends CollectionEvent {
  const DrawRequested();
}

class RevealDismissed extends CollectionEvent {
  const RevealDismissed();
}

class ShatterCopyRequested extends CollectionEvent {
  final String cardId;
  final CardVariant variant;
  const ShatterCopyRequested(this.cardId, this.variant);

  @override
  List<Object?> get props => [cardId, variant];
}
