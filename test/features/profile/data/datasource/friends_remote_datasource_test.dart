import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/data/datasource/friends_remote_datasource.dart';
import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/features/profile/domain/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with one scripted reply, and keeps the last request.
///
/// A [body] that is a `String` is sent as plain text, as the API sends its
/// errors; anything else is sent as JSON. When [throws] is set, the request
/// fails with that kind of error instead of being answered.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object? body;
  final DioExceptionType? throws;
  RequestOptions? request;

  _FakeAdapter({this.status = 200, this.body = const {}, this.throws});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final type = throws;
    if (type != null) throw DioException(requestOptions: options, type: type);
    final reply = body;
    if (reply is String) {
      return ResponseBody.fromString(reply, status, headers: {
        Headers.contentTypeHeader: ['text/plain'],
      });
    }
    return ResponseBody.fromString(jsonEncode(reply), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

FriendsRemoteDataSource _dataSource(_FakeAdapter adapter) =>
    FriendsRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

const _gnomon = {
  'deck_id': 'meridian-01',
  'card_id': 'gnomon',
  'art_url': 'https://example.test/gnomon.png',
};

const _sam = {'friend_id': '42', 'nickname': 'Sam', 'picture': _gnomon};

const _profile = {
  'has_profile': true,
  'nickname': 'Kai',
  'picture': _gnomon,
  'friend_code': 'K7QM2XPA',
  'friends_turned_off': false,
  'waiting_requests': 1,
};

typedef _Call = Future<Object?> Function(FriendsRemoteDataSource friends);

/// One route: what the app calls, where it posts, with what body, the words
/// for anything that goes wrong, and an answer it can read.
typedef _Route = ({
  String name,
  _Call call,
  String path,
  Map<String, dynamic> body,
  String callMessage,
  Map<String, Object?> reply,
});

final List<_Route> _routes = [
  (
    name: 'profile',
    call: (friends) => friends.profile(),
    path: '/v1/friends/profile',
    body: {},
    callMessage: "We couldn't load your friends.",
    reply: _profile,
  ),
  (
    name: 'saveProfile with a picture',
    call: (friends) => friends.saveProfile(
          nickname: 'Kai',
          picture: const CardPicture(
            deckId: 'meridian-01',
            cardId: 'gnomon',
            artUrl: 'https://example.test/gnomon.png',
          ),
        ),
    path: '/v1/friends/profile/save',
    body: {
      'nickname': 'Kai',
      'picture_deck_id': 'meridian-01',
      'picture_card_id': 'gnomon',
    },
    callMessage: "We couldn't save your nickname and picture. Try again.",
    reply: _profile,
  ),
  (
    name: 'saveProfile with no picture',
    call: (friends) => friends.saveProfile(nickname: 'Kai'),
    path: '/v1/friends/profile/save',
    body: {'nickname': 'Kai', 'picture_deck_id': '', 'picture_card_id': ''},
    callMessage: "We couldn't save your nickname and picture. Try again.",
    reply: _profile,
  ),
  (
    name: 'pictures',
    call: (friends) => friends.pictures(),
    path: '/v1/friends/pictures',
    body: {},
    callMessage: "We couldn't load your cards.",
    reply: {'pictures': []},
  ),
  (
    name: 'resetCode',
    call: (friends) => friends.resetCode(),
    path: '/v1/friends/code/reset',
    body: {},
    callMessage: "We couldn't make you a new code. Try again.",
    reply: _profile,
  ),
  (
    name: 'find',
    call: (friends) => friends.find('K7QM2XPA'),
    path: '/v1/friends/find',
    body: {'friend_code': 'K7QM2XPA'},
    callMessage: "We couldn't look up that code. Try again.",
    reply: {'student': _sam, 'relation': 'none'},
  ),
  (
    name: 'requests',
    call: (friends) => friends.requests(),
    path: '/v1/friends/requests',
    body: {},
    callMessage: "We couldn't load your friends.",
    reply: {'requests': []},
  ),
  (
    name: 'sendRequest by code',
    call: (friends) => friends.sendRequest('K7QM2XPA', FriendRequestVia.code),
    path: '/v1/friends/requests/send',
    body: {'friend_code': 'K7QM2XPA', 'via': 'code'},
    callMessage: "We couldn't send the request. Try again.",
    reply: {'result': 'sent'},
  ),
  (
    name: 'sendRequest by link',
    call: (friends) => friends.sendRequest('K7QM2XPA', FriendRequestVia.link),
    path: '/v1/friends/requests/send',
    body: {'friend_code': 'K7QM2XPA', 'via': 'link'},
    callMessage: "We couldn't send the request. Try again.",
    reply: {'result': 'sent'},
  ),
  (
    name: 'acceptRequest',
    call: (friends) => friends.acceptRequest('9'),
    path: '/v1/friends/requests/accept',
    body: {'request_id': '9'},
    callMessage: "We couldn't accept the request. Try again.",
    reply: {'friend': _sam},
  ),
  (
    name: 'declineRequest',
    call: (friends) => friends.declineRequest('9'),
    path: '/v1/friends/requests/decline',
    body: {'request_id': '9'},
    callMessage: "We couldn't decline the request. Try again.",
    reply: {},
  ),
  (
    name: 'friends',
    call: (friends) => friends.friends(),
    path: '/v1/friends/list',
    body: {},
    callMessage: "We couldn't load your friends.",
    reply: {'friends': []},
  ),
  (
    name: 'remove',
    call: (friends) => friends.remove('42'),
    path: '/v1/friends/remove',
    body: {'friend_id': '42'},
    callMessage: "We couldn't remove that friend. Try again.",
    reply: {},
  ),
  (
    name: 'block',
    call: (friends) => friends.block('42'),
    path: '/v1/friends/block',
    body: {'friend_id': '42'},
    callMessage: "We couldn't block that student. Try again.",
    reply: {},
  ),
  (
    name: 'unblock',
    call: (friends) => friends.unblock('42'),
    path: '/v1/friends/unblock',
    body: {'friend_id': '42'},
    callMessage: "We couldn't unblock that student. Try again.",
    reply: {},
  ),
  (
    name: 'blocked',
    call: (friends) => friends.blocked(),
    path: '/v1/friends/blocked',
    body: {},
    callMessage: "We couldn't load the students you've blocked.",
    reply: {'blocked': []},
  ),
  (
    name: 'report with a note',
    call: (friends) =>
        friends.report('42', ReportReason.rudeNickname, 'Called me names.'),
    path: '/v1/friends/report',
    body: {
      'friend_id': '42',
      'reason': 'rude_nickname',
      'note': 'Called me names.',
    },
    callMessage: "We couldn't send the report. Try again.",
    reply: {},
  ),
  (
    name: 'report with no note',
    call: (friends) => friends.report('42', ReportReason.other, ''),
    path: '/v1/friends/report',
    body: {'friend_id': '42', 'reason': 'other'},
    callMessage: "We couldn't send the report. Try again.",
    reply: {},
  ),
];

Matcher _throws<T extends Failure>(String message) =>
    throwsA(isA<T>().having((f) => f.message, 'message', message));

Matcher _refused(int status, String message) => throwsA(isA<RefusedFailure>()
    .having((f) => f.statusCode, 'statusCode', status)
    .having((f) => f.message, 'message', message));

void main() {
  setUpAll(AppLogger.disable);

  group('posts to its route', () {
    for (final route in _routes) {
      test('${route.name} posts its body to ${route.path}', () async {
        final adapter = _FakeAdapter(body: route.reply);

        await route.call(_dataSource(adapter));

        expect(adapter.request!.method, 'POST');
        expect(adapter.request!.path, route.path);
        expect(adapter.request!.data, route.body);
      });
    }
  });

  group('reads the answer', () {
    test('a profile', () async {
      final profile = await _dataSource(_FakeAdapter(body: _profile)).profile();

      expect(profile.hasProfile, isTrue);
      expect(profile.nickname, 'Kai');
      expect(profile.picture?.cardId, 'gnomon');
      expect(profile.friendCode, 'K7QM2XPA');
      expect(profile.friendsTurnedOff, isFalse);
      expect(profile.waitingRequests, 1);
    });

    test('no profile yet', () async {
      final profile = await _dataSource(_FakeAdapter(body: {
        'has_profile': false,
        'friends_turned_off': false,
        'waiting_requests': 0,
      })).profile();

      expect(profile.hasProfile, isFalse);
      expect(profile.nickname, isEmpty);
      expect(profile.picture, isNull);
      expect(profile.friendCode, isEmpty);
    });

    test('the cards to pick from', () async {
      final pictures = await _dataSource(_FakeAdapter(body: {
        'pictures': [
          {..._gnomon, 'name': 'Gnomon'},
        ],
      })).pictures();

      expect(pictures.single.name, 'Gnomon');
      expect(pictures.single.picture.deckId, 'meridian-01');
      expect(pictures.single.picture.artUrl, 'https://example.test/gnomon.png');
    });

    test('a found student and how the two are connected', () async {
      final found = await _dataSource(_FakeAdapter(body: {
        'student': _sam,
        'relation': 'request_received',
      })).find('K7QM2XPA');

      expect(found.student.friendId, '42');
      expect(found.relation, FriendRelation.requestReceived);
    });

    test('the waiting requests', () async {
      final requests = await _dataSource(_FakeAdapter(body: {
        'requests': [
          {'request_id': '9', 'from': _sam, 'sent_at': '2026-10-26T09:30:00Z'},
        ],
      })).requests();

      expect(requests.single.requestId, '9');
      expect(requests.single.from.nickname, 'Sam');
      expect(requests.single.sentAt, DateTime.utc(2026, 10, 26, 9, 30));
    });

    test('a request that made two students friends', () async {
      final sent = await _dataSource(
        _FakeAdapter(body: {'result': 'now_friends'}),
      ).sendRequest('K7QM2XPA', FriendRequestVia.code);

      expect(sent.result, SendFriendRequestResult.nowFriends);
    });

    test('the friend an accepted request made', () async {
      final accepted = await _dataSource(
        _FakeAdapter(body: {'friend': _sam}),
      ).acceptRequest('9');

      expect(accepted.friend.nickname, 'Sam');
    });

    test('the friends and the blocked students', () async {
      final friends = await _dataSource(_FakeAdapter(body: {
        'friends': [_sam],
      })).friends();
      final blocked = await _dataSource(_FakeAdapter(body: {
        'blocked': [_sam],
      })).blocked();

      expect(friends.single.friendId, '42');
      expect(blocked.single.friendId, '42');
    });

    test('an empty answer to a call that returns nothing', () async {
      await _dataSource(_FakeAdapter(body: '')).remove('42');
    });
  });

  group('words for a status the API refuses with', () {
    final cases = <(String, _Call, int, String)>[
      (
        'saveProfile',
        (friends) => friends.saveProfile(nickname: 'Kai'),
        422,
        'Please pick a different nickname.',
      ),
      (
        'find',
        (friends) => friends.find('K7QM2XPA'),
        404,
        "We couldn't find that code. Check it and try again.",
      ),
      (
        'sendRequest',
        (friends) => friends.sendRequest('K7QM2XPA', FriendRequestVia.code),
        404,
        "We couldn't find that code. Check it and try again.",
      ),
      (
        'sendRequest',
        (friends) => friends.sendRequest('K7QM2XPA', FriendRequestVia.code),
        409,
        'You have 100 friends. Remove one to add another.',
      ),
      (
        'sendRequest',
        (friends) => friends.sendRequest('K7QM2XPA', FriendRequestVia.code),
        422,
        "That's your own code.",
      ),
      (
        'acceptRequest',
        (friends) => friends.acceptRequest('9'),
        404,
        'That request has expired.',
      ),
      (
        'acceptRequest',
        (friends) => friends.acceptRequest('9'),
        409,
        'One of you already has 100 friends.',
      ),
      (
        'block',
        (friends) => friends.block('42'),
        404,
        "We couldn't find that student.",
      ),
      (
        'report',
        (friends) => friends.report('42', ReportReason.bullying, ''),
        404,
        "We couldn't find that student.",
      ),
    ];

    for (final (name, call, status, message) in cases) {
      test('$name: $status says "$message"', () async {
        await expectLater(
          call(_dataSource(_FakeAdapter(status: status, body: 'raw'))),
          _refused(status, message),
        );
      });
    }

    for (final route in _routes) {
      test('${route.name}: 403 says friends is turned off', () async {
        await expectLater(
          route.call(_dataSource(_FakeAdapter(status: 403, body: 'off'))),
          _refused(403, 'Friends is turned off for your account.'),
        );
      });

      test('${route.name}: 429 says it was done a lot today', () async {
        await expectLater(
          route.call(_dataSource(_FakeAdapter(status: 429, body: 'slow'))),
          _refused(429, "You've done that a lot today. Try again tomorrow."),
        );
      });
    }
  });

  group("anything else gets the call's own words", () {
    for (final route in _routes) {
      test('${route.name}: a server error', () async {
        await expectLater(
          route.call(_dataSource(_FakeAdapter(status: 500, body: 'boom'))),
          _throws<ServerFailure>(route.callMessage),
        );
      });

      test('${route.name}: no connection', () async {
        await expectLater(
          route.call(_dataSource(
              _FakeAdapter(throws: DioExceptionType.connectionError))),
          _throws<NetworkFailure>(route.callMessage),
        );
      });
    }

    for (final route in _routes) {
      // A call that answers with nothing reads nothing.
      if (route.reply.isEmpty) continue;
      test('${route.name}: an answer it cannot read', () async {
        await expectLater(
          route.call(_dataSource(_FakeAdapter(body: {'unexpected': true}))),
          _throws<UnknownFailure>(route.callMessage),
        );
      });
    }
  });
}
