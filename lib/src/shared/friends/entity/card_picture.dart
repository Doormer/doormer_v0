import 'package:equatable/equatable.dart';

/// The card a student picked as their picture, as friends see it.
class CardPicture extends Equatable {
  final String deckId;
  final String cardId;

  /// The card's standard art.
  final String artUrl;

  const CardPicture({
    required this.deckId,
    required this.cardId,
    required this.artUrl,
  });

  @override
  List<Object?> get props => [deckId, cardId, artUrl];
}
