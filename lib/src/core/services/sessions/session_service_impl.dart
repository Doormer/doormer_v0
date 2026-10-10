import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/token_storage/token_storage.dart';
import 'package:doormer/src/core/utils/app_logger.dart';

class SessionServiceImpl implements SessionService {
  final TokenStorage _tokenStorage;
  late Dio _dio;

  SessionServiceImpl({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  void setDio(Dio newDio) {
    _dio = newDio;
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      AppLogger.info('Access token retrieved from storage.');
      return token;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve access token',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    AppLogger.info('User logged out and tokens cleared.');

    //TODO: Notify the app about the logout
  }

  @override
  Future<String?> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      AppLogger.error(
          'No refresh token available. User needs to log in again.');
      throw AuthFailure('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '/v1/token/refresh',
        options: Options(
          extra: {'skipAuth': true},
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      final newAccessToken = response.data['access_token'] as String;
      await _tokenStorage.saveAccessToken(newAccessToken);

      AppLogger.info('Access token renewed.');
      return newAccessToken;
    } on DioException catch (e, stackTrace) {
      AppLogger.error('Failed to refresh token',
          error: e, stackTrace: stackTrace);
      throw AuthFailure('Failed to refresh token');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error while refreshing token',
          error: e, stackTrace: stackTrace);
      throw UnknownFailure('An unexpected error occurred');
    }
  }

  @override
  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    try {
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveRefreshToken(refreshToken);
      AppLogger.info('Tokens saved.');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save tokens',
          error: e, stackTrace: stackTrace);
      throw DatabaseFailure('Session could not be saved. Please try again.');
    }
  }
}
