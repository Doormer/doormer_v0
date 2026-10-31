import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/collection/data/datasource/collection_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/failure/photo_question_failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The worked solution is read from the app's assets.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLogger.disable);

  late QuestionsRemoteDataSource questions;
  late CollectionRemoteDataSource collection;

  setUp(() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.test',
      headers: {'Authorization': 'Bearer test-token'},
    ))
      ..httpClientAdapter = fakeBackend(
        delay: Duration.zero,
        solveDelay: Duration.zero,
        clock: () => DateTime.utc(2026, 10, 10, 9),
      );
    questions = QuestionsRemoteDataSourceImpl(dio: dio);
    collection = CollectionRemoteDataSourceImpl(dio: dio);
  });

  QuestionsRemoteDataSource questionsOn({
    Duration solveDelay = Duration.zero,
    DateTime Function()? clock,
  }) =>
      QuestionsRemoteDataSourceImpl(
        dio: Dio(BaseOptions(
          baseUrl: 'https://api.test',
          headers: {'Authorization': 'Bearer test-token'},
        ))
          ..httpClientAdapter = fakeBackend(
            delay: Duration.zero,
            solveDelay: solveDelay,
            clock: clock ?? () => DateTime.utc(2026, 10, 10, 9),
          ),
      );

  Future<PhotoQuestionResponseModel> sendPhoto(
          QuestionsRemoteDataSource questions, String key) =>
      questions.submitPhotoQuestion(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
        idempotencyKey: key,
      );

  // The longest a test waits for an answer, so a photo that is never
  // answered fails the test instead of hanging it.
  const longestWait = Duration(seconds: 5);

  /// Sends a photo without waiting for its answer. The test's teardown waits
  /// for it, so its solve never outlives the test.
  Future<PhotoQuestionResponseModel> startSending(
      QuestionsRemoteDataSource questions, String key) {
    final answer = sendPhoto(questions, key).timeout(longestWait);
    addTearDown(() => answer.then((_) {}, onError: (_) {}));
    return answer;
  }

  // The fake's day ends at the device's next midnight, so the expected
  // resets are built in the device's zone, and the tests pass in any zone.
  final local = DateTime.utc(2026, 10, 10, 9).toLocal();
  final midnight = DateTime(local.year, local.month, local.day + 1);

  test('starts with three saved questions, newest first', () async {
    final saved = await questions.loadSolvedQuestions();

    expect([for (final question in saved.questions) question.questionId],
        ['101', '102', '103']);
    expect(saved.questions.first.askedAt, DateTime.utc(2026, 10, 9, 9));
    expect(saved.nextCursor, isNull);
  });

  test('a photo comes back solved and joins the top of the saved list',
      () async {
    final solved = await questions.submitPhotoQuestion(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
      idempotencyKey: 'photo-1',
    );
    final saved = await questions.loadSolvedQuestions();

    expect(solved.status, PhotoQuestionSolveStatus.solved);
    expect(solved.solution?.steps, isNotEmpty);
    expect(saved.questions, hasLength(4));
    expect(saved.questions.first.questionId, solved.questionId);
    expect(saved.questions.first.askedAt, DateTime.utc(2026, 10, 10, 9));
  });

  test('a saved question opens a worked solution under its own topic',
      () async {
    final opened = await questions.loadQuestion('102');

    expect((opened.questionId, opened.topic),
        ('102', 'Algebra - Linear equations'));
    expect(opened.solution?.steps, isNotEmpty);
  });

  test('an unknown question is an error', () async {
    await expectLater(questions.loadQuestion('999'), throwsA(isA<Failure>()));
  });

  test('revealing an answer pays 3 quarks, the first time only', () async {
    final first = await questions.revealAnswer('101');
    final again = await questions.revealAnswer('101');

    expect((first.quarksEarned, first.quarkBalance), (3, 203));
    expect((again.quarksEarned, again.quarkBalance), (0, 203));
  });

  test('the balance shows what reveals earn and draws cost', () async {
    await questions.revealAnswer('101');
    await collection.draw('meridian-01', idempotencyKey: 'draw-1');

    expect((await questions.loadQuarkBalance()).quarkBalance, 163);
  });

  test('every diagram is a placeholder that loads without the network',
      () async {
    final opened = await questions.loadQuestion('101');
    final diagrams = [
      for (final step in opened.solution!.steps)
        for (final segment in step.body)
          if (segment is VisualSolutionSegmentModel) segment,
    ];

    expect(diagrams, isNotEmpty);
    expect([for (final diagram in diagrams) diagram.url],
        everyElement(startsWith('data:image/png;base64,')));
  });

  test(
      'a student starts the day with five questions, back at the next midnight',
      () async {
    final limit = await questions.loadDailyLimit();

    expect(limit.toEntity(), DailyLimit(questionsLeft: 5, resetsAt: midnight));
  });

  test(
      'each solved photo uses a question, and the answer says how many are '
      'left', () async {
    final solved = await sendPhoto(questions, 'photo-1');
    final limit = await questions.loadDailyLimit();

    expect(solved.toEntity().dailyLimit,
        DailyLimit(questionsLeft: 4, resetsAt: midnight));
    expect(limit.toEntity(), DailyLimit(questionsLeft: 4, resetsAt: midnight));
  });

  test('the sixth photo of the day is turned away with the daily limit',
      () async {
    for (var photo = 1; photo <= 5; photo++) {
      await sendPhoto(questions, 'photo-$photo');
    }

    await expectLater(
      sendPhoto(questions, 'photo-6'),
      throwsA(isA<DailyLimitReachedFailure>().having((f) => f.dailyLimit,
          'dailyLimit', DailyLimit(questionsLeft: 0, resetsAt: midnight))),
    );
  });

  test('a repeated key gets its first answer back and uses no question',
      () async {
    final first = await sendPhoto(questions, 'photo-1');
    final again = await sendPhoto(questions, 'photo-1');
    final limit = await questions.loadDailyLimit();

    expect(again.questionId, first.questionId);
    expect(limit.questionsLeft, 4);
  });

  test(
      'a photo sent while another is being solved is turned away until it '
      'finishes', () async {
    final questions =
        questionsOn(solveDelay: const Duration(milliseconds: 200));

    final first = startSending(questions, 'photo-1');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await expectLater(sendPhoto(questions, 'photo-2').timeout(longestWait),
        throwsA(isA<PhotoBeingSolvedFailure>()));

    await first;
    final second = await sendPhoto(questions, 'photo-2').timeout(longestWait);

    expect(second.status, PhotoQuestionSolveStatus.solved);
  });

  test('the same photo sent again while it is being solved is turned away too',
      () async {
    final questions =
        questionsOn(solveDelay: const Duration(milliseconds: 200));

    final first = startSending(questions, 'photo-1');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await expectLater(sendPhoto(questions, 'photo-1').timeout(longestWait),
        throwsA(isA<PhotoBeingSolvedFailure>()));

    final firstAnswer = await first;
    final again = await sendPhoto(questions, 'photo-1').timeout(longestWait);

    expect(again.questionId, firstAnswer.questionId);
  });

  test('a new day brings the questions back', () async {
    var now = DateTime.utc(2026, 10, 10, 9);
    final questions = questionsOn(clock: () => now);
    for (var photo = 1; photo <= 5; photo++) {
      await sendPhoto(questions, 'photo-$photo');
    }

    now = midnight.add(const Duration(minutes: 1));
    final limit = await questions.loadDailyLimit();

    final nextMidnight =
        DateTime(midnight.year, midnight.month, midnight.day + 1);
    expect(
        limit.toEntity(), DailyLimit(questionsLeft: 5, resetsAt: nextMidnight));
  });

  test('a photo without a key is refused', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.test',
      headers: {'Authorization': 'Bearer test-token'},
    ))
      ..httpClientAdapter =
          fakeBackend(delay: Duration.zero, solveDelay: Duration.zero);

    await expectLater(
      dio.post<Object?>(
        '/v1/questions/photo',
        data: Uint8List.fromList([1, 2, 3]),
        options: Options(headers: {'Content-Type': 'image/jpeg'}),
      ),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 400)),
    );
  });
}
