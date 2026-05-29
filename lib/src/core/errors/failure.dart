abstract class Failure {
  final String message;
  Failure(this.message);

  @override
  String toString() => message;
}

/// Network-related failures (timeout, no internet)
class NetworkFailure extends Failure {
  NetworkFailure([super.message = "Network error"]);
}

/// Server-related failures (5xx responses)
class ServerFailure extends Failure {
  ServerFailure([super.message = "Server error occurred"]);
}

/// API response failures (4xx responses)
class ApiFailure extends Failure {
  final int statusCode;

  ApiFailure(this.statusCode, [String message = "Unexpected API response"])
      : super("Error $statusCode: $message");
}

/// Authentication failures (401, invalid credentials)
class AuthFailure extends Failure {
  AuthFailure([super.message = "Authentication failed"]);
}

/// Validation failures (422, invalid input data)
class ValidationFailure extends Failure {
  ValidationFailure([super.message = "Validation failed"]);
}

/// Database / local storage failures
class DatabaseFailure extends Failure {
  DatabaseFailure([super.message = "Database error occurred"]);
}

/// General unknown failure (catch-all)
class UnknownFailure extends Failure {
  UnknownFailure([super.message = "An unknown error occurred"]);
}
