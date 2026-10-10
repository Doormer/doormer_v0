import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';

/// An interceptor for handling session-related logic in network requests.
///
/// [SessionInterceptor] attaches the access token to request headers. When a
/// request is rejected with 401, it renews the access token with the stored
/// refresh token and retries the request once; if renewal fails, it expires
/// the session and logs the user out.
class SessionInterceptor extends Interceptor {
  /// Marks a request already retried with a renewed access token, so a second
  /// 401 ends the session instead of refreshing again.
  static const retriedAfterRefreshKey = 'retriedAfterRefresh';

  final SessionService _sessionService;
  final GlobalSessionBloc _globalSessionBloc;
  final Dio _dio;
  Future<String?>? _refreshInFlight;

  /// Creates a [SessionInterceptor] instance.
  ///
  /// Parameters:
  /// - [sessionService]: Provides methods to retrieve and renew session tokens.
  /// - [globalSessionBloc]: Manages session state and handles session expiration.
  /// - [dio]: The client this interceptor belongs to, used to retry requests.
  SessionInterceptor({
    required SessionService sessionService,
    required GlobalSessionBloc globalSessionBloc,
    required Dio dio,
  })  : _sessionService = sessionService,
        _globalSessionBloc = globalSessionBloc,
        _dio = dio;

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
    } catch (e, stackTrace) {
      AppLogger.error("Failed to attach access token",
          error: e, stackTrace: stackTrace);
    }
    handler.next(options);
  }

  /// Renews the access token after a 401 and retries the request once.
  ///
  /// Requests that skip auth (login, signup, the refresh call itself) and
  /// errors other than 401 are passed on untouched.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || request.extra['skipAuth'] == true) {
      return handler.next(err);
    }
    if (request.extra[retriedAfterRefreshKey] == true) {
      await _expireSession();
      return handler.next(err);
    }

    try {
      await _renewAccessToken();
    } catch (e, stackTrace) {
      AppLogger.error('Could not renew the session',
          error: e, stackTrace: stackTrace);
      await _expireSession();
      return handler.next(err);
    }

    request.extra[retriedAfterRefreshKey] = true;
    // Dio sends a FormData body only once, so the retry needs a fresh copy.
    final body = request.data;
    if (body is FormData) request.data = body.clone();
    try {
      handler.resolve(await _dio.fetch(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Requests rejected at the same time wait on one refresh call.
  Future<String?> _renewAccessToken() => _refreshInFlight ??= _sessionService
      .refreshToken()
      .whenComplete(() => _refreshInFlight = null);

  Future<void> _expireSession() async {
    _globalSessionBloc.add(ExpireSession());
    await _sessionService.logout();
  }
}
