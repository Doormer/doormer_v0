import 'dart:convert';

import 'package:dio/dio.dart';

/// A fake answer: a status code and a body.
///
/// A [String] body is sent as plain text, as `taka-api` sends its errors. Any
/// other body is sent as JSON, and no body sends nothing.
class FakeResponse {
  final int status;
  final Object? body;

  const FakeResponse(this.status, [this.body]);

  /// A 200 with a JSON [body].
  const FakeResponse.ok(Object this.body) : status = 200;

  bool get isSuccess => status >= 200 && status < 300;

  ResponseBody toResponseBody() => switch (body) {
        null => ResponseBody.fromString('', status),
        final String text => ResponseBody.fromString(text, status, headers: {
            Headers.contentTypeHeader: ['text/plain; charset=utf-8'],
          }),
        final json =>
          ResponseBody.fromString(jsonEncode(json), status, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          }),
      };
}
