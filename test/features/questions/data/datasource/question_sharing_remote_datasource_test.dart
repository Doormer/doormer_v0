import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/datasource/question_sharing_remote_datasource.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
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

QuestionSharingRemoteDataSource _dataSource(_FakeAdapter adapter) =>
    QuestionSharingRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

const _alex = {'friend_id': '11', 'nickname': 'Alex'};
const _sam = {
  'friend_id': '7',
  'nickname': 'Sam',
  'picture': {
    'deck_id': 'cinder-01',
    'card_id': 'flint',
    'art_url': 'https://example.test/flint.png',
  },
};

/// A row of Shared with me, as the API sends it.
const _sharedRow = {
  'question_id': '501',
  'topic': 'Algebra - Linear equations',
  'method': 'Inverse operations',
  'question_text': 'Solve x + 3 = 7',
  'asked_at': '2026-10-30T08:12:09Z',
  'photo_url': 'https://example.test/photo/501.jpg?sig=p',
  'shared_by': _sam,
  'shared_at': '2026-11-01T05:30:00Z',
};

typedef _Call = Future<Object?> Function(QuestionSharingRemoteDataSource);

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
    name: 'friends',
    call: (sharing) => sharing.friends(),
    path: '/v1/friends/list',
    body: {},
    callMessage: "We couldn't load your friends.",
    reply: {
      'friends': [_alex, _sam],
    },
  ),
  (
    name: 'share',
    call: (sharing) => sharing.share('501', ['13', '11']),
    path: '/v1/questions/share',
    body: {
      'question_id': '501',
      'friend_ids': ['13', '11'],
    },
    callMessage: "We couldn't share that question. Try again.",
    reply: {
      'shared_with': [_alex],
    },
  ),
  (
    name: 'stopSharing',
    call: (sharing) => sharing.stopSharing('501'),
    path: '/v1/questions/share/stop',
    body: {'question_id': '501'},
    callMessage: "We couldn't stop sharing. Try again.",
    reply: {},
  ),
  (
    name: 'sharedQuestions, the first page',
    call: (sharing) => sharing.sharedQuestions(),
    path: '/v1/questions/shared',
    body: {},
    callMessage: "We couldn't load the questions shared with you.",
    reply: {'questions': []},
  ),
  (
    name: 'sharedQuestions, a later page',
    call: (sharing) => sharing.sharedQuestions(cursor: '9001'),
    path: '/v1/questions/shared',
    body: {'cursor': '9001'},
    callMessage: "We couldn't load the questions shared with you.",
    reply: {'questions': []},
  ),
  (
    name: 'removeSharedQuestion',
    call: (sharing) => sharing.removeSharedQuestion('501'),
    path: '/v1/questions/shared/remove',
    body: {'question_id': '501'},
    callMessage: "We couldn't remove that question. Try again.",
    reply: {},
  ),
  (
    name: 'report with a note',
    call: (sharing) => sharing.report(
          friendId: '7',
          questionId: '501',
          reason: ReportReason.bullying,
          note: 'Wrote something mean on it.',
        ),
    path: '/v1/friends/report',
    body: {
      'friend_id': '7',
      'reason': 'bullying',
      'note': 'Wrote something mean on it.',
      'question_id': '501',
    },
    callMessage: "We couldn't send the report. Try again.",
    reply: {},
  ),
  (
    name: 'report with no note',
    call: (sharing) => sharing.report(
          friendId: '7',
          questionId: '501',
          reason: ReportReason.other,
          note: '',
        ),
    path: '/v1/friends/report',
    body: {'friend_id': '7', 'reason': 'other', 'question_id': '501'},
    callMessage: "We couldn't send the report. Try again.",
    reply: {},
  ),
  (
    name: 'block',
    call: (sharing) => sharing.block('7'),
    path: '/v1/friends/block',
    body: {'friend_id': '7'},
    callMessage: "We couldn't block that student. Try again.",
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
    test('the friends, in the order the API gives them', () async {
      final friends = await _dataSource(_FakeAdapter(body: {
        'friends': [_alex, _sam],
      })).friends();

      expect([for (final friend in friends) friend.nickname], ['Alex', 'Sam']);
      expect(friends.last.picture?.cardId, 'flint');
    });

    test('everyone the question is now shared with', () async {
      final sharedWith = await _dataSource(_FakeAdapter(body: {
        'shared_with': [_alex, _sam],
      })).share('501', ['7']);

      expect([for (final friend in sharedWith) friend.friendId], ['11', '7']);
    });

    test('a page of Shared with me, and where the next starts', () async {
      final page = await _dataSource(_FakeAdapter(body: {
        'questions': [_sharedRow],
        'next_cursor': '9001',
      })).sharedQuestions();

      final shared = page.toEntity();
      expect(shared.questions.single.question.questionId, '501');
      expect(shared.questions.single.sharedBy.nickname, 'Sam');
      expect(
          shared.questions.single.sharedAt, DateTime.utc(2026, 11, 1, 5, 30));
      expect(shared.nextCursor, '9001');
    });

    test('an empty answer to a call that returns nothing', () async {
      await _dataSource(_FakeAdapter(body: '')).stopSharing('501');
    });
  });

  group('words for a status the API refuses with', () {
    final cases = <(String, _Call, int, String)>[
      (
        'friends, before setup',
        (sharing) => sharing.friends(),
        409,
        'Add friends on Profile to share questions with them.',
      ),
      (
        'share, to someone no longer a friend',
        (sharing) => sharing.share('501', ['7']),
        404,
        'Your friends list changed. Check the ticks and send again.',
      ),
      (
        'share, before setup',
        (sharing) => sharing.share('501', ['7']),
        409,
        'Add friends on Profile to share questions with them.',
      ),
      (
        'share, a question not solved',
        (sharing) => sharing.share('501', ['7']),
        422,
        'Only a solved question can be shared.',
      ),
      (
        'stopSharing, a question that is not there',
        (sharing) => sharing.stopSharing('501'),
        404,
        "We couldn't find this question.",
      ),
      (
        'report, once the share has ended',
        (sharing) => sharing.report(
              friendId: '7',
              questionId: '501',
              reason: ReportReason.bullying,
              note: '',
            ),
        404,
        "That question isn't shared with you any more.",
      ),
      (
        'block, a student out of reach',
        (sharing) => sharing.block('7'),
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

    // A status with no words of its own, for this call or for any call.
    for (final (name, call, status, callMessage)
        in <(String, _Call, int, String)>[
      (
        'sharedQuestions',
        (sharing) => sharing.sharedQuestions(),
        404,
        "We couldn't load the questions shared with you.",
      ),
      (
        'removeSharedQuestion',
        (sharing) => sharing.removeSharedQuestion('501'),
        404,
        "We couldn't remove that question. Try again.",
      ),
      (
        'share',
        (sharing) => sharing.share('501', ['7']),
        400,
        "We couldn't share that question. Try again.",
      ),
    ]) {
      test("$name: $status says the call's words, never what the API wrote",
          () async {
        await expectLater(
          call(_dataSource(_FakeAdapter(
            status: status,
            body: 'no row in question_share for question 501',
          ))),
          throwsA(isA<ApiFailure>()
              .having((f) => f.statusCode, 'statusCode', status)
              .having(
                  (f) => f.message, 'message', 'Error $status: $callMessage')),
        );
      });
    }
  });
}
