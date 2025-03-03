import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:doormer/src/features/auth/domain/repository/auth_repository.dart';
import 'package:doormer/src/shared/user/entity/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  //final AuthRemoteDataSource dataSource;
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
    try {
      final loginResponse = await remoteDataSource.signup(email, password);
      AppLogger.info(loginResponse.accessToken);
      // Save tokens using SessionService
      await sessionService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
      // Return User entity
      return User(userRegistrationStatus: 1);
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    // Call remote data source to get LoginResponseModel
    final loginResponse = await remoteDataSource.login(email, password);
    AppLogger.info('$loginResponse');

    // Save tokens using SessionService
    await sessionService.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );

    // Return User entity
    return User(userRegistrationStatus: 1);
  }

  @override
  Future<void> verifyEmail(
      {required String email, required String code}) async {
    await dataSource.verifyEmail(email, code);
  }

  @override
  Future<void> logout() async {
    await sessionService.logout(); // Clear tokens and reset session
  }

  @override
  Future<User> signInWithGoogle(String idToken) async {
    final loginResponse = await remoteDataSource.verifyGoogleIdToken(idToken);

    // Save tokens using SessionService
    await sessionService.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );
    // Return User entity
    return User(userRegistrationStatus: 1);
  }
}
