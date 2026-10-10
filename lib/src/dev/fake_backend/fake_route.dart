import 'dart:async';

import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';

/// One kind of request the fake backend answers.
class FakeRoute {
  /// `GET`, `POST`, `PUT` and so on.
  final String method;

  /// The API path, or the host for a request sent elsewhere. See
  /// [FakeRequest.target].
  final String target;

  final FutureOr<FakeResponse> Function(FakeRequest request) answer;

  /// Whether the request must carry a bearer token, as the API's signed-in
  /// requests do. Any token will do.
  final bool needsToken;

  const FakeRoute(this.method, this.target, this.answer,
      {this.needsToken = true});

  String get key => '$method $target';
}
