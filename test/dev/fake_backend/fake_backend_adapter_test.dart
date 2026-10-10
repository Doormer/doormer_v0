import 'package:dio/dio.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend_adapter.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _dio(List<FakeRoute> routes, {String? token = 'test-token'}) => Dio(
      BaseOptions(
        baseUrl: 'https://api.test',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    )..httpClientAdapter = FakeBackendAdapter(routes);

Matcher _failsWithStatus(int status) => throwsA(isA<DioException>()
    .having((e) => e.response?.statusCode, 'status', status));

void main() {
  setUpAll(AppLogger.disable);

  test('answers a route with its JSON body', () async {
    final dio = _dio([
      FakeRoute('POST', '/v1/hello',
          (_) => const FakeResponse.ok({'greeting': 'hi'})),
    ]);

    final response = await dio.post('/v1/hello');

    expect(response.statusCode, 200);
    expect(response.data, {'greeting': 'hi'});
  });

  test('sends a text body as plain text, as the API sends its errors',
      () async {
    final dio = _dio([
      FakeRoute('POST', '/v1/refuse',
          (_) => const FakeResponse(409, 'not enough quarks')),
    ]);

    await expectLater(
      dio.post('/v1/refuse'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 409)
          .having((e) => e.response?.data, 'body', 'not enough quarks')),
    );
  });

  test('answers 404 for a request it has no route for', () async {
    await expectLater(_dio([]).post('/v1/unknown'), _failsWithStatus(404));
  });

  test('answers 401 when the route needs a token and none was sent', () async {
    final dio = _dio(
      [FakeRoute('POST', '/v1/private', (_) => const FakeResponse.ok({}))],
      token: null,
    );

    await expectLater(dio.post('/v1/private'), _failsWithStatus(401));
  });

  test('answers without a token when the route needs none', () async {
    final dio = _dio(
      [
        FakeRoute('POST', '/v1/login', (_) => const FakeResponse.ok({}),
            needsToken: false),
      ],
      token: null,
    );

    expect((await dio.post('/v1/login')).statusCode, 200);
  });

  test('routes a request sent to another host by that host', () async {
    final dio = _dio([
      FakeRoute('PUT', 'storage.test', (_) => const FakeResponse(201),
          needsToken: false),
    ]);

    final response = await dio.put('https://storage.test/uploads/cv.pdf');

    expect(response.statusCode, 201);
  });

  test('gives a route the fields of a JSON body or a form', () async {
    final dio = _dio([
      FakeRoute(
          'POST', '/v1/echo', (request) => FakeResponse.ok(request.fields)),
    ]);

    final json = await dio.post('/v1/echo', data: {'deck_id': 'meridian-01'});
    final form = await dio.post('/v1/echo',
        data: FormData.fromMap({'email': 'ana@example.test'}));

    expect(json.data, {'deck_id': 'meridian-01'});
    expect(form.data, {'email': 'ana@example.test'});
  });

  group('with an Idempotency-Key', () {
    late int answers;
    late Dio dio;

    setUp(() {
      answers = 0;
      dio = _dio([
        FakeRoute(
            'POST', '/v1/draw', (_) => FakeResponse.ok({'answer': ++answers})),
      ]);
    });

    Future<Object?> draw(String key) async => (await dio.post('/v1/draw',
            options: Options(headers: {'Idempotency-Key': key})))
        .data;

    test('replays the first answer for a key it has seen', () async {
      expect(await draw('a'), {'answer': 1});
      expect(await draw('a'), {'answer': 1});
      expect(answers, 1);
    });

    test('answers a new key afresh', () async {
      await draw('a');

      expect(await draw('b'), {'answer': 2});
    });
  });

  test('does not replay a refusal, so a retry is tried again', () async {
    var refuse = true;
    final dio = _dio([
      FakeRoute(
        'POST',
        '/v1/draw',
        (_) => refuse
            ? const FakeResponse(409, 'refused')
            : const FakeResponse.ok({'drawn': true}),
      ),
    ]);
    final sameKey = Options(headers: {'Idempotency-Key': 'a'});

    await expectLater(
        dio.post('/v1/draw', options: sameKey), _failsWithStatus(409));
    refuse = false;

    expect(
        (await dio.post('/v1/draw', options: sameKey)).data, {'drawn': true});
  });

  test('answers 500 when a route fails', () async {
    final dio = _dio([
      FakeRoute('POST', '/v1/broken', (_) => throw StateError('broken')),
    ]);

    await expectLater(dio.post('/v1/broken'), _failsWithStatus(500));
  });
}
