import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:doormer/src/features/auth/domain/repository/auth_repository.dart';
import 'package:doormer/src/shared/user/entity/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource dataSource;
  final AuthRemoteDataSource remoteDataSource;
  final SessionService sessionService;

  AuthRepositoryImpl({
    required this.dataSource,
    required this.sessionService,
    required this.remoteDataSource,
  });

  @override
  Future<User> signup({required String email, required String password}) async {
    final loginResponse = await remoteDataSource.signup(email, password);
    
    try {
      await sessionService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
    } on Failure {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save session tokens after signup', error: e, stackTrace: stackTrace);
      throw DatabaseFailure('Session could not be saved. Please try again.');
    }
    return User(userRegistrationStatus: 0);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final loginResponse = await remoteDataSource.login(email, password);
    try {
      await sessionService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
    } on Failure {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save session tokens after login', error: e, stackTrace: stackTrace);
      throw DatabaseFailure('Session could not be saved. Please try again.');
    }
    return loginResponse.user!.toEntity();
  }

  @override
  Future<void> verifyEmail(
      {required String email, required String code}) async {
    await dataSource.verifyEmail(email, code);
  }

  @override
  Future<void> logout() async {
    await sessionService.logout();
  }

  @override
  Future<User> signInWithGoogle(String idToken) async {
    final loginResponse = await remoteDataSource.verifyGoogleIdToken(idToken);
    try {
      await sessionService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
    } on Failure {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save session tokens after Google sign-in', error: e, stackTrace: stackTrace);
      throw DatabaseFailure('Session could not be saved. Please try again.');
    }
    return loginResponse.user?.toEntity() ?? User(userRegistrationStatus: 0);
  }
}
