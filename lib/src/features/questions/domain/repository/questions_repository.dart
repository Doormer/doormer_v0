import 'dart:typed_data';

import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';

abstract class QuestionsRepository {
  /// [idempotencyKey] names the photo: every try at sending it uses the same
  /// one.
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  });

  Future<PhotoQuestionSolveOutcome> loadSampleSolution();

  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId);

  /// One page of the student's solved questions, newest first. No cursor
  /// asks for the first page.
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor});

  Future<AnswerReward> revealAnswer(String questionId);

  Future<int> loadQuarkBalance();

  /// How many questions the student has left today, and when they reset.
  Future<DailyLimit> loadDailyLimit();
}
