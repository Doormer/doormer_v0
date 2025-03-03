import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';

/// An interceptor for handling session-related logic in network requests.
///
/// [SessionInterceptor] is responsible for attaching the access token to
/// request headers, and handling 401 Unauthorized responses by logging out
/// the user when no refresh token mechanism is available.
class SessionInterceptor extends Interceptor {
  final SessionService _sessionService;
  final GlobalSessionBloc _globalSessionBloc;

  /// Creates a [SessionInterceptor] instance.
  ///
  /// Parameters:
  /// - [sessionService]: Provides methods to retrieve session tokens.
  /// - [globalSessionBloc]: Manages session state and handles session expiration.
  SessionInterceptor({
    required SessionService sessionService,
    required GlobalSessionBloc globalSessionBloc,
  })  : _sessionService = sessionService,
        _globalSessionBloc = globalSessionBloc;

  /// Attaches the access token to the request headers.
  ///
  /// If an access token is available, it is included in the `Authorization` header
  /// of the request in the format `Bearer <token>`.
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Check if the current request should skip authentication.
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }
    try {
      final accessToken = await _sessionService.getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (e) {
      AppLogger.error("Failed to attach access token: $e");
    }
    handler.next(options);
  }

  /// Handles errors and attempts to resolve 401 Unauthorized responses.
  ///
  /// Since there is no refresh token mechanism available, if a 401 error occurs,
  /// the user is immediately logged out.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // No refresh token available; expire session and log out.
      _globalSessionBloc.add(ExpireSession());
      await _sessionService.logout();
    }

    // Forward the error if it can't be resolved.
    handler.next(err);
  }
}
