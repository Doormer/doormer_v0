import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:doormer/src/features/auth/data/repository/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Answers every request with [body], as JSON.
class _ScriptedAdapter implements HttpClientAdapter {
  final Map<String, Object> body;

  _ScriptedAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(jsonEncode(body), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

/// Keeps the tokens the repository saves. Signing in uses nothing else.
class _RecordingSessionService implements SessionService {
  String? savedAccessToken;
  String? savedRefreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    savedAccessToken = accessToken;
    savedRefreshToken = refreshToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  // The API answers a log-in with the two tokens and nothing about the
  // student.
  test('logging in works when the API answers with only the two tokens',
      () async {
    final sessions = _RecordingSessionService();
    final repository = AuthRepositoryImpl(
      dataSource: AuthLocalDataSource(),
      sessionService: sessions,
      remoteDataSource: AuthRemoteDataSource(
        sessionService: sessions,
        googleSignIn: GoogleSignIn(),
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = _ScriptedAdapter(
            {'access_token': 'access', 'refresh_token': 'refresh'},
          ),
      ),
    );

    await repository.login(email: 'kai@example.test', password: 'secret123');

    expect((sessions.savedAccessToken, sessions.savedRefreshToken),
        ('access', 'refresh'));
  });
}
