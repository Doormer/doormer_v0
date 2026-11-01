import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/failure/photo_question_failures.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';

class QuestionsRepositoryImpl implements QuestionsRepository {
  final QuestionsRemoteDataSource remoteDataSource;
  final QuestionsLocalDataSource localDataSource;

  QuestionsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    try {
      final response = await remoteDataSource.submitPhotoQuestion(
        imageBytes: imageBytes,
        contentType: contentType,
        idempotencyKey: idempotencyKey,
      );
      return response.toEntity();
    } on DailyLimitReachedFailure catch (f) {
      // A refusal is the API working as meant, not a failure.
      AppLogger.info('Photo question repository passed on a refusal: '
          '${f.message}');
      rethrow;
    } on PhotoBeingSolvedFailure catch (f) {
      AppLogger.info('Photo question repository passed on a refusal: '
          '${f.message}');
      rethrow;
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Photo question repository failed',
          error: f, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Photo question repository unexpected error',
          error: e, stackTrace: stackTrace);
      throw UnknownFailure('We could not submit your photo. Please try again.');
    }
  }

  @override
  Future<AnswerReward> revealAnswer(String questionId) async {
    final response = await remoteDataSource.revealAnswer(questionId);
    return response.toEntity();
  }

  @override
  Future<int> loadQuarkBalance() async {
    final response = await remoteDataSource.loadQuarkBalance();
    return response.quarkBalance;
  }

  @override
  Future<DailyLimit> loadDailyLimit() async {
    final response = await remoteDataSource.loadDailyLimit();
    return response.toEntity();
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() {
    return localDataSource.loadSampleSolution();
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) async {
    final response = await remoteDataSource.loadQuestion(questionId);
    return response.toEntity();
  }

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async {
    final response = await remoteDataSource.loadSolvedQuestions(cursor: cursor);
    return response.toEntity();
  }
}
