import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

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

QuestionsRemoteDataSource _dataSource(_FakeAdapter adapter) =>
    QuestionsRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

Matcher _throws<T extends Failure>(String message) =>
    throwsA(isA<T>().having((f) => f.message, 'message', message));

const _couldNotConnect =
    "We couldn't connect. Check your connection and try again.";
const _somethingWentWrong = 'Something went wrong. Try again.';

void main() {
  setUpAll(AppLogger.disable);

  group('revealAnswer', () {
    test('posts the question id and reads the reward', () async {
      final adapter = _FakeAdapter(body: {
        'quarks_earned': 3,
        'quark_balance': 131,
      });

      final reply = await _dataSource(adapter).revealAnswer('123');

      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.path, '/v1/questions/reveal-answer');
      expect(adapter.request!.data, {'question_id': '123'});
      expect(reply.quarksEarned, 3);
      expect(reply.quarkBalance, 131);
    });

    test('a successful no-pay reveal reads as zero earned', () async {
      final adapter = _FakeAdapter(body: {
        'quarks_earned': 0,
        'quark_balance': 128,
      });

      final reply = await _dataSource(adapter).revealAnswer('123');

      expect(reply.quarksEarned, 0);
      expect(reply.quarkBalance, 128);
    });
  });

  group('submitPhotoQuestion', () {
    test('waits as long as the API gives a solve', () async {
      final adapter = _FakeAdapter(body: {'status': 'unreadable'});

      await _dataSource(adapter).submitPhotoQuestion(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
        idempotencyKey: 'key-1',
      );

      expect(adapter.request!.path, '/v1/questions/photo');
      expect(adapter.request!.receiveTimeout, const Duration(seconds: 660));
    });
  });

  group('loadQuarkBalance', () {
    test('posts an empty body and reads the balance', () async {
      final adapter = _FakeAdapter(body: {'quark_balance': 128});

      final reply = await _dataSource(adapter).loadQuarkBalance();

      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.path, '/v1/quarks/balance');
      expect(adapter.request!.data, isEmpty);
      expect(reply.quarkBalance, 128);
    });
  });

  group('loadQuestion', () {
    test('posts the question id and reads the solved outcome', () async {
      final adapter = _FakeAdapter(body: {
        'status': 'solved',
        'question_id': '57',
        'note': 'The width is derived.',
        'topic': 'Geometry - Area',
        'method': 'Trigonometry and parallelogram area',
        'solution': {
          'schema_version': '3.0',
          'steps': [
            {
              'title': 'Find the width',
              'body': [
                {'type': 'text', 'value': 'Use the angle.'},
              ],
            },
          ],
          'final_answer': {
            'body': [
              {'type': 'math', 'latex': r'160', 'alt': '160'},
            ],
          },
        },
      });

      final reply = await _dataSource(adapter).loadQuestion('57');

      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.path, '/v1/questions/solution');
      expect(adapter.request!.data, {'question_id': '57'});
      expect(reply.questionId, '57');
      expect(reply.note, 'The width is derived.');
      expect(reply.topic, 'Geometry - Area');
      expect(reply.method, 'Trigonometry and parallelogram area');
      expect(reply.solution!.steps.single.title, 'Find the width');
    });
  });

  group('failures carry the collection-style messages', () {
    test('a timeout or no connection', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        await expectLater(
          _dataSource(_FakeAdapter(throws: type)).revealAnswer('123'),
          _throws<NetworkFailure>(_couldNotConnect),
          reason: type.name,
        );
      }
    });

    test('signed out', () async {
      final adapter = _FakeAdapter(status: 401, body: {'msg': 'no token'});
      await expectLater(
        _dataSource(adapter).loadQuarkBalance(),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('a bad id or unknown question is an API failure with its status',
        () async {
      for (final status in [400, 404]) {
        final adapter = _FakeAdapter(status: status, body: {'msg': 'server'});
        await expectLater(
          _dataSource(adapter).revealAnswer('bad'),
          _throws<ApiFailure>('Error $status: $_somethingWentWrong'),
          reason: '$status',
        );
      }
    });

    test('a server error', () async {
      final adapter = _FakeAdapter(status: 500, body: {'msg': 'server'});
      await expectLater(
        _dataSource(adapter).revealAnswer('123'),
        _throws<ServerFailure>(_somethingWentWrong),
      );
    });

    test('a response that is not JSON', () async {
      final adapter = _FakeAdapter(body: 'not json');
      await expectLater(
        _dataSource(adapter).loadQuarkBalance(),
        _throws<UnknownFailure>(_somethingWentWrong),
      );
    });

    test('a response with a field missing', () async {
      final adapter = _FakeAdapter(body: {'quark_balance': 128});
      await expectLater(
        _dataSource(adapter).revealAnswer('123'),
        _throws<UnknownFailure>(_somethingWentWrong),
      );
    });
  });
}
