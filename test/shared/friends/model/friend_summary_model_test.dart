import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a student with a picture', () {
    final summary = FriendSummaryModel.fromJson({
      'friend_id': '42',
      'nickname': 'Sam',
      'picture': {
        'deck_id': 'meridian-01',
        'card_id': 'gnomon',
        'art_url': 'https://example.test/gnomon.png',
      },
    }).toEntity();

    expect(
      summary,
      const FriendSummary(
        friendId: '42',
        nickname: 'Sam',
        picture: CardPicture(
          deckId: 'meridian-01',
          cardId: 'gnomon',
          artUrl: 'https://example.test/gnomon.png',
        ),
      ),
    );
  });

  test('a student with no picture has none', () {
    final summary =
        FriendSummaryModel.fromJson({'friend_id': '7', 'nickname': 'Alex'})
            .toEntity();

    expect(summary.picture, isNull);
  });

  test("reads a friend's level", () {
    final summary = FriendSummaryModel.fromJson({
      'friend_id': '42',
      'nickname': 'Sam',
      'level': {'number': 6, 'suns': 0, 'moons': 1, 'stars': 2},
    }).toEntity();

    expect(
      summary.level,
      const Level(number: 6, suns: 0, moons: 1, stars: 2),
    );
  });

  test('a student shown with no level has none', () {
    final summary =
        FriendSummaryModel.fromJson({'friend_id': '7', 'nickname': 'Alex'})
            .toEntity();

    expect(summary.level, isNull);
  });

  test('reads the list under its key', () {
    final summaries = FriendSummaryModel.listFromJson({
      'friends': [
        {'friend_id': '7', 'nickname': 'Alex'},
        {'friend_id': '42', 'nickname': 'Sam'},
      ],
    }, 'friends');

    expect([for (final s in summaries) s.nickname], ['Alex', 'Sam']);
  });

  test('a student with no ID cannot be read', () {
    expect(
      () => FriendSummaryModel.fromJson({'nickname': 'Sam'}),
      throwsA(isA<TypeError>()),
    );
  });
}
