import 'dart:typed_data';

import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_daily_limit_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements QuestionsRepository {
  final dailyLimit =
      DailyLimit(questionsLeft: 3, resetsAt: DateTime.utc(2026, 10, 18, 11));
  int calls = 0;

  @override
  Future<DailyLimit> loadDailyLimit() async {
    calls++;
    return dailyLimit;
  }

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

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) =>
      throw UnimplementedError();
}

void main() {
  test('returns the daily limit the repository reads', () async {
    final repository = _FakeRepository();

    final dailyLimit = await LoadDailyLimitUseCase(repository)();

    expect(repository.calls, 1);
    expect(dailyLimit, same(repository.dailyLimit));
  });
}
