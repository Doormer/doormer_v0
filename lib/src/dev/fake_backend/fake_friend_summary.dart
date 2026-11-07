import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_decks.dart';

/// [student] as the API's `FriendSummary`.
Map<String, Object?> fakeFriendSummary(FakeStudent student) => {
      'friend_id': student.id,
      'nickname': student.nickname,
      ...fakePictureField(student.picture),
    };

/// The `picture` field, left out with no picture, or for a card no longer in
/// the catalog.
Map<String, Object?> fakePictureField(FakePicture? picture) {
  if (picture == null) return const {};
  final card = fakeDeckById(picture.deckId)?.cardById(picture.cardId);
  if (card == null) return const {};
  return {
    'picture': {
      'deck_id': picture.deckId,
      'card_id': picture.cardId,
      'art_url': card.artUrl,
    },
  };
}
