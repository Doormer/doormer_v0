import 'package:dio/dio.dart';
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
    } on DioException catch (e) {
      AppLogger.error('Signup Error: ${e.response?.data}');
      throw Exception(e.response?.data ?? 'SignUp Failed');
    }
  }

  Future<LoginResponseModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {
          'auth_type': '1',
          'email': email,
          'password': password,
        },
        options: Options(
          extra: {'skipAuth': true},
        ),
      );

      AppLogger.info('Passing to UserModel.fromJson: ${response.data}');
      return LoginResponseModel.fromJson(response.data);
    } catch (e, stacktrace) {
      AppLogger.error('Error in login API call: $e\n$stacktrace');
      throw Exception('Failed to login');
    }
  }

  // Sends verification code to verify email
  // This endpoint is assumed to require authentication so no skipAuth flag is added.
  Future<void> verifyEmail(String email, String code) async {
    try {
      await dio.post(
        '/confirm-email', // Replace with your actual endpoint
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Email confirmation failed');
    }
  }

  // Exchange Google ID token for backend tokens.
  Future<LoginResponseModel> verifyGoogleIdToken(String googleIdToken) async {
    AppLogger.info('Google Id Token: $googleIdToken');
    try {
      final formData = FormData.fromMap({
        'auth_type': 2,
        'token': googleIdToken,
      });

      final response = await dio.post(
        '/signup', // Your backend endpoint
        data: formData,
        options: Options(
          extra: {'skipAuth': true},
        ),
      );

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to exchange Google ID token for backend tokens');
      }
    } catch (e) {
      throw Exception(
          'Error while exchanging Google ID token: ${e.toString()}');
    }
  }
}
