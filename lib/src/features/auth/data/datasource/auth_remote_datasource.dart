import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/auth/data/model/login_response_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRemoteDataSource {
  final SessionService sessionService;
  final GoogleSignIn googleSignIn;
  final Dio dio;

  AuthRemoteDataSource({
    required this.sessionService,
    required this.googleSignIn,
    required this.dio,
  });

  Future<LoginResponseModel> signup(String email, String password) async {
    try {
      final formData = FormData.fromMap({
        'auth_type': 1,
        'email': email,
        'password': password,
      });

      final response = await dio.post(
        '/signup',
        data: formData,
        options: Options(
          extra: {'skipAuth': true},
        ),
      );
      final loginResponseModel = LoginResponseModel.fromJson(response.data);
      return loginResponseModel;
    } on DioException catch (e, stackTrace) {
      AppLogger.error('Signup failed', error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(e, userFacingMessage: 'Sign up failed. Please try again.');
    }
  }

  Future<LoginResponseModel> login(String email, String password) async {
    try {
      final formData = FormData.fromMap({
        'auth_type': 1,
        'email': email,
        'password': password,
      });
      AppLogger.info('Requesting Login: $formData');
      final response = await dio.post(
        '/login',
        data: formData,
        options: Options(
          extra: {'skipAuth': true},
        ),
      );

      AppLogger.info('Passing to UserModel.fromJson: ${response.data}');
      return LoginResponseModel.fromJson(response.data);
    } on DioException catch (e, stackTrace) {
      AppLogger.error('Login failed', error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(e, userFacingMessage: 'Login failed. Please check your credentials.');
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      await dio.post(
        '/confirm-email',
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e, stackTrace) {
      AppLogger.error('Email verification failed', error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(e, userFacingMessage: 'Email confirmation failed. Please try again.');
    }
  }

  Future<LoginResponseModel> verifyGoogleIdToken(String googleIdToken) async {
    AppLogger.info('Google Id Token: $googleIdToken');
    try {
      final formData = FormData.fromMap({
        'auth_type': 2,
        'token': googleIdToken,
      });

      final response = await dio.post(
        '/signup',
        data: formData,
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw ServerFailure(
            'Sign up failed. Please try again.');
      }
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 400 &&
          e.response!.data.toString().contains('user is already registered')) {
        AppLogger.warn('User already registered, retrying with /login');
        return _retryWithLogin(googleIdToken);
      }
      AppLogger.error('Google ID token exchange failed', error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(e,
          userFacingMessage: 'Sign in with Google failed. Please try again.');
    }
  }

  Future<LoginResponseModel> _retryWithLogin(String googleIdToken) async {
    try {
      final formData = FormData.fromMap({
        'auth_type': 2,
        'token': googleIdToken,
      });

      final response = await dio.post(
        '/login',
        data: formData,
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw ServerFailure('Sign in with Google failed. Please try again.');
      }
    } on DioException catch (e, stackTrace) {
      AppLogger.error('Login retry after signup failure', error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(e,
          userFacingMessage: 'Sign in with Google failed. Please try again.');
    }
  }
}
