import 'dart:typed_data';

import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_question_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements QuestionsRepository {
  String? questionId;

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) async {
    this.questionId = questionId;
    return const PhotoQuestionSolveOutcome(
      status: PhotoQuestionSolveStatus.solved,
      questionId: '57',
      solution: SolutionDocument(
        schemaVersion: '3.0',
        steps: [SolutionStep(title: 'Step 1', body: [])],
        finalAnswer: FinalAnswer(body: []),
      ),
    );
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() =>
      throw UnimplementedError();

  @override
  Future<int> loadQuarkBalance() => throw UnimplementedError();

  @override
  Future<AnswerReward> revealAnswer(String questionId) =>
      throw UnimplementedError();

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) =>
      throw UnimplementedError();
}

void main() {
  test('delegates to the repository', () async {
    final repository = _FakeRepository();
    final useCase = LoadQuestionUseCase(repository);

    final outcome = await useCase('57');

    expect(repository.questionId, '57');
    expect(outcome.questionId, '57');
    expect(outcome.solution, isNotNull);
  });
}
