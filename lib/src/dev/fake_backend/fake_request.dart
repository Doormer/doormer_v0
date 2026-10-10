import 'package:dio/dio.dart';

/// What a fake route needs to know about a request the app made.
class FakeRequest {
  /// `GET`, `POST`, `PUT` and so on.
  final String method;

  /// The API path, such as `/v1/login`. For a request sent to another host,
  /// such as a storage upload, that host instead.
  final String target;

  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> headers;

  /// The body as the app passed it: a JSON map, [FormData], bytes or text.
  final Object? body;

  const FakeRequest({
    required this.method,
    required this.target,
    this.queryParameters = const {},
    this.headers = const {},
    this.body,
  });

  factory FakeRequest.fromOptions(RequestOptions options) {
    final address = Uri.parse(options.path);
    return FakeRequest(
      method: options.method.toUpperCase(),
      target: address.host.isEmpty ? address.path : address.host,
      queryParameters: {
        ...address.queryParameters,
        ...options.queryParameters,
      },
      headers: options.headers,
      body: options.data,
    );
  }

  /// Which route answers this request.
  String get key => '$method $target';

  /// The fields of a JSON or form body, or none for any other body.
  Map<String, Object?> get fields {
    final data = body;
    if (data is Map) {
      return {
        for (final field in data.entries) field.key.toString(): field.value
      };
    }
    if (data is FormData) {
      return {for (final field in data.fields) field.key: field.value};
    }
    return const {};
  }

  /// A header's value. Header names are not case-sensitive.
  String? header(String name) {
    final wanted = name.toLowerCase();
    for (final header in headers.entries) {
      if (header.key.toLowerCase() == wanted) return header.value?.toString();
    }
    return null;
  }

  /// The token after `Bearer` in the `Authorization` header, if any.
  String? get bearerToken {
    final authorization = header('Authorization') ?? '';
    if (!authorization.startsWith('Bearer ')) return null;
    final token = authorization.substring('Bearer '.length).trim();
    return token.isEmpty ? null : token;
  }
}
