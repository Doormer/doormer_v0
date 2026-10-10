import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service_impl.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  _InMemoryTokenStorage({this.accessToken, this.refreshToken});

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> deleteAccessToken() async => accessToken = null;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> deleteRefreshToken() async => refreshToken = null;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

/// Answers every request with one scripted reply and keeps what was sent.
class _OneReplyAdapter implements HttpClientAdapter {
  final int status;
  final Object body;
  final List<RequestOptions> requests = [];

  _OneReplyAdapter(this.status, this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

SessionServiceImpl _service(TokenStorage storage, HttpClientAdapter adapter) =>
    SessionServiceImpl(
      tokenStorage: storage,
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

void main() {
  setUpAll(AppLogger.disable);

  test(
      'sends the refresh token as a bearer token and keeps the new access token',
      () async {
    final storage =
        _InMemoryTokenStorage(accessToken: 'old-access', refreshToken: 'refresh');
    final adapter = _OneReplyAdapter(200, {'access_token': 'new-access'});

    final renewed = await _service(storage, adapter).refreshToken();

    expect(renewed, 'new-access');
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/token/refresh');
    expect(request.headers['Authorization'], 'Bearer refresh');
    expect(request.extra['skipAuth'], isTrue,
        reason: 'the interceptor must not replace the refresh token');
    expect(storage.accessToken, 'new-access');
    expect(storage.refreshToken, 'refresh',
        reason: 'the 30-day sign-in window is fixed, so it is never replaced');
  });

  test('fails without calling the API when no refresh token is stored',
      () async {
    final storage = _InMemoryTokenStorage(accessToken: 'old-access');
    final adapter = _OneReplyAdapter(200, {'access_token': 'new-access'});

    final renewal = _service(storage, adapter).refreshToken();

    await expectLater(renewal, throwsA(isA<AuthFailure>()));
    expect(adapter.requests, isEmpty);
  });

  test('fails and keeps the stored tokens when the API rejects the refresh token',
      () async {
    final storage =
        _InMemoryTokenStorage(accessToken: 'old-access', refreshToken: 'refresh');
    final adapter = _OneReplyAdapter(401, {});

    final renewal = _service(storage, adapter).refreshToken();

    await expectLater(renewal, throwsA(isA<AuthFailure>()));
    expect(storage.accessToken, 'old-access');
    expect(storage.refreshToken, 'refresh');
  });
}
