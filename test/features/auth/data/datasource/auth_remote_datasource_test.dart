import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Answers requests with scripted replies, in order, and keeps each path.
///
/// A reply body that is a `String` is sent as plain text, as the API sends its
/// errors; anything else is sent as JSON.
class _FakeAdapter implements HttpClientAdapter {
  final List<(int, Object)> replies;
  final List<String> paths = [];

  _FakeAdapter(this.replies);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final (status, body) = replies[paths.length - 1];
    if (body is String) {
      return ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: ['text/plain'],
      });
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// The data source keeps a session service, but signing in never uses it.
class _UnusedSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

AuthRemoteDataSource _dataSource(_FakeAdapter adapter) => AuthRemoteDataSource(
      sessionService: _UnusedSessionService(),
      googleSignIn: GoogleSignIn(),
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

const _signedIn = {
  'access_token': 'access',
  'refresh_token': 'refresh',
  'user_info': {'user_registration_status': 0},
};

void main() {
  setUpAll(AppLogger.disable);

  test('signs up at /v1/signup', () async {
    final adapter = _FakeAdapter([(200, _signedIn)]);

    await _dataSource(adapter).signup('ana@example.test', 'secret');

    expect(adapter.paths, ['/v1/signup']);
  });

  test('logs in at /v1/login', () async {
    final adapter = _FakeAdapter([(200, _signedIn)]);

    await _dataSource(adapter).login('ana@example.test', 'secret');

    expect(adapter.paths, ['/v1/login']);
  });

  test('signs up with Google at /v1/signup', () async {
    final adapter = _FakeAdapter([(200, _signedIn)]);

    await _dataSource(adapter).verifyGoogleIdToken('google-id-token');

    expect(adapter.paths, ['/v1/signup']);
  });

  test('logs in with Google at /v1/login when already signed up', () async {
    final adapter = _FakeAdapter([
      (400, 'user is already registered'),
      (200, _signedIn),
    ]);

    await _dataSource(adapter).verifyGoogleIdToken('google-id-token');

    expect(adapter.paths, ['/v1/signup', '/v1/login']);
  });
}
