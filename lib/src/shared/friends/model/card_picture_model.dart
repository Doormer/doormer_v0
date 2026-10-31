import '../entity/card_picture.dart';

/// The API's `FriendPicture`: `{deck_id, card_id, art_url}`.
class CardPictureModel {
  final String deckId;
  final String cardId;
  final String artUrl;

  const CardPictureModel({
    required this.deckId,
    required this.cardId,
    required this.artUrl,
  });

  factory CardPictureModel.fromJson(Map<String, dynamic> json) =>
      CardPictureModel(
        deckId: json['deck_id'] as String,
        cardId: json['card_id'] as String,
        artUrl: json['art_url'] as String,
      );

  /// A picture, or null for a body the API left out.
  static CardPictureModel? maybeFromJson(Object? json) => json == null
      ? null
      : CardPictureModel.fromJson(json as Map<String, dynamic>);

  CardPicture toEntity() =>
      CardPicture(deckId: deckId, cardId: cardId, artUrl: artUrl);
}
