import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/collection/data/datasource/collection_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
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
}
