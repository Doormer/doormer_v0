import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements QuestionsRepository {
  int calls = 0;
  String? contentType;
  String? idempotencyKey;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    calls++;
    this.contentType = contentType;
    this.idempotencyKey = idempotencyKey;
    return const PhotoQuestionSolveOutcome(
      status: PhotoQuestionSolveStatus.unreadable,
      questionId: 'q1',
      solution: null,
    );
  }

  @override
  Future<DailyLimit> loadDailyLimit() => throw UnimplementedError();

  @override
  Future<int> loadQuarkBalance() => throw UnimplementedError();

  @override
  Future<AnswerReward> revealAnswer(String questionId) =>
      throw UnimplementedError();

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() =>
      throw UnimplementedError();

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) =>
      throw UnimplementedError();
}

void main() {
  test('hands the photo key and its content type to the repository', () async {
    final repository = _FakeRepository();

    await SubmitPhotoQuestionUseCase(repository)(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
      idempotencyKey: 'photo-key-1',
    );

    expect(repository.calls, 1);
    expect(repository.idempotencyKey, 'photo-key-1');
    expect(repository.contentType, 'image/jpeg');
  });

  test('a file that is not a photo is refused before it is sent', () async {
    final repository = _FakeRepository();

    await expectLater(
      SubmitPhotoQuestionUseCase(repository)(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'notes.txt',
        mimeType: 'text/plain',
        idempotencyKey: 'photo-key-1',
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.calls, 0);
  });
}
