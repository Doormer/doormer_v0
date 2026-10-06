import 'dart:typed_data';

import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements QuestionsRepository {
  int calls = 0;

  @override
  Future<int> loadQuarkBalance() async {
    calls++;
    return 128;
  }

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
    final useCase = LoadQuarkBalanceUseCase(repository);

    final balance = await useCase();

    expect(repository.calls, 1);
    expect(balance, 128);
  });
}
