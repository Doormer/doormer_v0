import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/interceptors/session_interceptor.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accepts only `Bearer new-access`; anything else is 401. Keeps the
/// Authorization header each request arrived with.
class _AcceptsNewAccessToken implements HttpClientAdapter {
  final List<String?> authorizations = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final authorization = options.headers['Authorization'] as String?;
    authorizations.add(authorization);
    final accepted = authorization == 'Bearer new-access';
    return ResponseBody.fromString('{}', accepted ? 200 : 401, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Rejects every request with 401, even after a refresh.
class _AlwaysUnauthorized implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString('{}', 401, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

/// Starts with an expired access token. [refreshToken] waits for [renewal], so
/// a test can hold the refresh open while more requests fail.
class _FakeSessionService implements SessionService {
  String? accessToken = 'expired-access';
  int refreshCalls = 0;
  int logoutCalls = 0;
  Completer<void> renewal = Completer<void>()..complete();
  bool refreshFails = false;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> refreshToken() async {
    refreshCalls++;
    await renewal.future;
    if (refreshFails) throw AuthFailure('rejected');
    return accessToken = 'new-access';
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    accessToken = null;
  }

  @override
  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {}
}

class _Client {
  final Dio dio;
  final GlobalSessionBloc sessionBloc;

  _Client(this.dio, this.sessionBloc);
}

_Client _client(_FakeSessionService session, HttpClientAdapter server) {
  final sessionBloc = GlobalSessionBloc(sessionService: session);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = server;
  dio.interceptors.add(SessionInterceptor(
    sessionService: session,
    globalSessionBloc: sessionBloc,
    dio: dio,
  ));
  return _Client(dio, sessionBloc);
}

Future<void> _until(bool Function() condition) async {
  while (!condition()) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

Matcher _rejectedWith(int status) => throwsA(isA<DioException>()
    .having((e) => e.response?.statusCode, 'status code', status));

void main() {
  setUpAll(AppLogger.disable);

  test('renews the access token after a 401 and retries the request', () async {
    final session = _FakeSessionService();
    final server = _AcceptsNewAccessToken();
    final client = _client(session, server);

    final response = await client.dio.get('/v1/profile');

    expect(response.statusCode, 200);
    expect(session.refreshCalls, 1);
    expect(server.authorizations,
        ['Bearer expired-access', 'Bearer new-access']);
    expect(session.logoutCalls, 0);
  });

  test('requests rejected at the same time share one refresh', () async {
    final session = _FakeSessionService()..renewal = Completer<void>();
    final server = _AcceptsNewAccessToken();
    final client = _client(session, server);

    final both =
        Future.wait([client.dio.get('/v1/a'), client.dio.get('/v1/b')]);
    // Hold the refresh open until both 401s have reached the interceptor.
    await _until(() => server.authorizations.length == 2);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    session.renewal.complete();
    final responses = await both;

    expect(responses.map((r) => r.statusCode), [200, 200]);
    expect(session.refreshCalls, 1);
  });

  test('a failed refresh expires the session and passes the 401 on', () async {
    final session = _FakeSessionService()..refreshFails = true;
    final client = _client(session, _AcceptsNewAccessToken());
    final sessionExpired = expectLater(
        client.sessionBloc.stream, emits(isA<SessionExpiredState>()));

    final request = client.dio.get('/v1/profile');

    await expectLater(request, _rejectedWith(401));
    await sessionExpired;
    expect(session.logoutCalls, 1);
  });

  test(
      'a request still rejected after the refresh expires the session '
      'without refreshing again', () async {
    final session = _FakeSessionService();
    final client = _client(session, _AlwaysUnauthorized());

    final request = client.dio.get('/v1/profile');

    await expectLater(request, _rejectedWith(401));
    expect(session.refreshCalls, 1);
    expect(session.logoutCalls, 1);
  });

  test('a 401 on a request that skips auth is passed on untouched', () async {
    final session = _FakeSessionService();
    final client = _client(session, _AlwaysUnauthorized());

    final request = client.dio
        .post('/v1/login', options: Options(extra: {'skipAuth': true}));

    await expectLater(request, _rejectedWith(401));
    expect(session.refreshCalls, 0);
    expect(session.logoutCalls, 0);
  });

  test('retries a FormData request, whose body Dio can send only once',
      () async {
    final session = _FakeSessionService();
    final client = _client(session, _AcceptsNewAccessToken());

    final response = await client.dio.post('/v1/candidate/register',
        data: FormData.fromMap({'first_name': 'Ana'}));

    expect(response.statusCode, 200);
    expect(session.refreshCalls, 1);
  });
}
