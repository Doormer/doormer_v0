import 'dart:typed_data';

import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements QuestionsRepository {
  String? questionId;

  @override
  Future<AnswerReward> revealAnswer(String questionId) async {
    this.questionId = questionId;
    return const AnswerReward(quarksEarned: 3, quarkBalance: 131);
  }

  @override
  Future<int> loadQuarkBalance() => throw UnimplementedError();

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
    final useCase = RevealAnswerUseCase(repository);

    final reward = await useCase('123');

    expect(repository.questionId, '123');
    expect(reward.quarksEarned, 3);
    expect(reward.quarkBalance, 131);
  });
}
