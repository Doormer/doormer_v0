import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/services/sessions/session_service_impl.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Signing in never uses the session service.
class _UnusedSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _InMemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  _InMemoryTokenStorage({this.refreshToken});

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

void main() {
  setUpAll(AppLogger.disable);

  late Dio dio;
  late AuthRemoteDataSource auth;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter =
          fakeBackend(delay: Duration.zero, solveDelay: Duration.zero);
    auth = AuthRemoteDataSource(
      sessionService: _UnusedSessionService(),
      googleSignIn: GoogleSignIn(),
      dio: dio,
    );
  });

  test('signing up gives tokens and a student who has not registered',
      () async {
    final signedUp = await auth.signup('ana@example.test', 'secret');

    expect(signedUp.accessToken, isNotEmpty);
    expect(signedUp.refreshToken, isNotEmpty);
    expect(signedUp.user?.userRegistrationStatus, 0);
  });

  test('any email and password sign in, as a registered student', () async {
    final signedIn = await auth.login('anyone@example.test', 'any password');

    expect(signedIn.accessToken, isNotEmpty);
    expect(signedIn.user?.userRegistrationStatus, 1);
  });

  test('each sign-in gets its own access token', () async {
    final first = await auth.login('ana@example.test', 'secret');
    final second = await auth.login('ana@example.test', 'secret');

    expect(second.accessToken, isNot(first.accessToken));
  });

  test('confirming an email succeeds', () async {
    await expectLater(
        auth.verifyEmail('ana@example.test', '123456'), completes);
  });

  test('renewing the session stores a new access token', () async {
    final tokens = _InMemoryTokenStorage(refreshToken: 'any refresh token');
    final session = SessionServiceImpl(tokenStorage: tokens, dio: dio);

    final renewed = await session.refreshToken();

    expect(renewed, isNotEmpty);
    expect(tokens.accessToken, renewed);
  });
}
