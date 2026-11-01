import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/levels/data/datasource/levels_remote_datasource.dart';
import 'package:doormer/src/features/levels/domain/entity/active_day_outcome.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with one scripted reply, and keeps the last request.
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

LevelsRemoteDataSource _dataSource(_FakeAdapter adapter) =>
    LevelsRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

const _progressAt32 = {
  'active_days': 32,
  'level': {'number': 4, 'suns': 0, 'moons': 1, 'stars': 0},
  'active_days_to_next_level': 13,
  'next_level_icon': 'star',
};

const _level4At32 = LevelProgress(
  activeDays: 32,
  level: Level(number: 4, suns: 0, moons: 1, stars: 0),
  activeDaysToNextLevel: 13,
  nextLevelIcon: LevelIcon.star,
);

Matcher _throws<T extends Failure>() => throwsA(isA<T>().having(
    (f) => f.message, 'message', "We couldn't count today as an active day."));

void main() {
  setUpAll(AppLogger.disable);

  test('posts an empty body to /v1/levels/active-day, and reads a new level',
      () async {
    final adapter = _FakeAdapter(body: {
      'counted': true,
      'new_icon': 'moon',
      'progress': _progressAt32,
    });

    final reply = await _dataSource(adapter).countActiveDay();

    expect(adapter.request!.method, 'POST');
    expect(adapter.request!.path, '/v1/levels/active-day');
    expect(adapter.request!.data, isEmpty);
    expect(
      reply.toEntity(),
      const ActiveDayOutcome(
        counted: true,
        newIcon: LevelIcon.moon,
        progress: _level4At32,
      ),
    );
  });

  test('a day already counted brings no new icon', () async {
    final reply = await _dataSource(_FakeAdapter(body: {
      'counted': false,
      'progress': _progressAt32,
    })).countActiveDay();

    expect(
      reply.toEntity(),
      const ActiveDayOutcome(counted: false, progress: _level4At32),
    );
  });

  test("a call that fails throws a failure in the app's own words", () async {
    await expectLater(
      _dataSource(_FakeAdapter(status: 500, body: 'boom')).countActiveDay(),
      _throws<ServerFailure>(),
    );
    await expectLater(
      _dataSource(_FakeAdapter(throws: DioExceptionType.connectionError))
          .countActiveDay(),
      _throws<NetworkFailure>(),
    );
  });

  test('an answer it cannot read is an unknown failure', () async {
    await expectLater(
      _dataSource(_FakeAdapter(body: {
        'counted': true,
        'new_icon': 'crown',
        'progress': _progressAt32,
      })).countActiveDay(),
      _throws<UnknownFailure>(),
    );
  });
}
