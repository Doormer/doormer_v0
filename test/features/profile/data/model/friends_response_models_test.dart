import 'package:doormer/src/features/profile/data/model/friends_response_models.dart';
import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:flutter_test/flutter_test.dart';

const _sam = {'friend_id': '42', 'nickname': 'Sam'};

void main() {
  group('relation', () {
    for (final (wire, relation) in [
      ('none', FriendRelation.none),
      ('request_sent', FriendRelation.requestSent),
      ('request_received', FriendRelation.requestReceived),
      ('friends', FriendRelation.friends),
      ('blocked_by_you', FriendRelation.blockedByYou),
      ('you', FriendRelation.you),
    ]) {
      test('"$wire" reads as $relation', () {
        final found = FoundStudentModel.fromJson({
          'student': _sam,
          'relation': wire,
        }).toEntity();

        expect(found.relation, relation);
      });
    }

    test('a relation the app does not know cannot be read', () {
      expect(
        () => FoundStudentModel.fromJson({
          'student': _sam,
          'relation': 'best_friends',
        }),
        throwsFormatException,
      );
    });
  });

  group('send result', () {
    test('"sent" and "now_friends"', () {
      expect(SendFriendRequestResponseModel.fromJson({'result': 'sent'}).result,
          SendFriendRequestResult.sent);
      expect(
          SendFriendRequestResponseModel.fromJson({'result': 'now_friends'})
              .result,
          SendFriendRequestResult.nowFriends);
    });

    test('a result the app does not know cannot be read', () {
      expect(
        () => SendFriendRequestResponseModel.fromJson({'result': 'queued'}),
        throwsFormatException,
      );
    });
  });

  test('a request with no readable time cannot be read', () {
    expect(
      () => FriendRequestModel.fromJson({
        'request_id': '9',
        'from': _sam,
        'sent_at': 'yesterday',
      }),
      throwsFormatException,
    );
  });

  test('a profile with friends turned off still reads', () {
    final profile = FriendProfileModel.fromJson({
      'has_profile': true,
      'nickname': 'Kai',
      'friend_code': 'K7QM2XPA',
      'friends_turned_off': true,
      'waiting_requests': 0,
    }).toEntity();

    expect(profile.friendsTurnedOff, isTrue);
    expect(profile.picture, isNull);
  });
}
