import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';

/// Converts a [DioException] to a typed [Failure] for consistent error handling
/// across all remote datasources.
///
/// [userFacingMessage] is the message shown in the UI — keep it
/// human-readable and free of technical jargon.
/// Server error details are not included in the [Failure] message; they are
/// logged at the call site via [AppLogger].
Failure dioExceptionToFailure(DioException e,
    {required String userFacingMessage}) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkFailure(userFacingMessage);
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401) {
        return AuthFailure(userFacingMessage);
      }
      if (statusCode == 422) {
        return ValidationFailure(userFacingMessage);
      }
      if (statusCode >= 500) {
        return ServerFailure(userFacingMessage);
      }
      return ApiFailure(statusCode, userFacingMessage);
    default:
      return UnknownFailure(userFacingMessage);
  }
}
