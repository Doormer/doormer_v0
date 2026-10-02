import 'package:equatable/equatable.dart';

/// One row of the deck list: how far a student is through one deck.
class DeckProgress extends Equatable {
  final String deckId;
  final String name;

  /// Cards held, not copies held.
  final int cardsHeld;
  final int cardsTotal;

  const DeckProgress({
    required this.deckId,
    required this.name,
    required this.cardsHeld,
    required this.cardsTotal,
  });

  @override
  List<Object?> get props => [deckId, name, cardsHeld, cardsTotal];
}
