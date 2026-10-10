import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// Answers a [Dio]'s requests from [FakeRoute]s, in memory, instead of
/// sending them anywhere.
///
/// Only the sending is fake: interceptors, error mapping and parsing still
/// run for real on what comes back.
class FakeBackendAdapter implements HttpClientAdapter {
  /// How long every answer takes.
  final Duration delay;

  final Map<String, FakeRoute> _routes;

  /// Successful answers, by request and `Idempotency-Key`, given again when
  /// the same key comes back. Simpler than `taka-api`, which re-reads the
  /// balance and checks the request matches; the app never re-sends a key
  /// with a different request.
  final _answersByIdempotencyKey = <String, FakeResponse>{};

  FakeBackendAdapter(Iterable<FakeRoute> routes, {this.delay = Duration.zero})
      : _routes = {for (final route in routes) route.key: route};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = FakeRequest.fromOptions(options);
    await Future<void>.delayed(delay);
    final response = await _answer(request);
    return response.toResponseBody();
  }

  Future<FakeResponse> _answer(FakeRequest request) async {
    final route = _routes[request.key];
    if (route == null) {
      AppLogger.warn('The fake backend has no answer for ${request.key}');
      return FakeResponse(
          404, 'The fake backend has no answer for ${request.key}');
    }
    if (route.needsToken && request.bearerToken == null) {
      return const FakeResponse(401, 'missing token');
    }

    final idempotencyKey = request.header('Idempotency-Key');
    final replayKey = '${request.key} $idempotencyKey';
    final earlier = _answersByIdempotencyKey[replayKey];
    if (idempotencyKey != null && earlier != null) return earlier;

    final FakeResponse response;
    try {
      response = await route.answer(request);
    } catch (e, stackTrace) {
      AppLogger.error('The fake backend failed to answer ${request.key}',
          error: e, stackTrace: stackTrace);
      return const FakeResponse(500, 'The fake backend failed');
    }
    if (idempotencyKey != null && response.isSuccess) {
      _answersByIdempotencyKey[replayKey] = response;
    }
    return response;
  }

  @override
  void close({bool force = false}) {}
}
