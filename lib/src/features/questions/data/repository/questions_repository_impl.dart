import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:uuid/uuid.dart';

class QuestionsRepositoryImpl implements QuestionsRepository {
  final QuestionsRemoteDataSource remoteDataSource;
  final QuestionsLocalDataSource localDataSource;
  final String Function() idempotencyKeyFactory;

  QuestionsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    String Function()? idempotencyKeyFactory,
  }) : idempotencyKeyFactory = idempotencyKeyFactory ?? _newIdempotencyKey;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    try {
      final response = await remoteDataSource.submitPhotoQuestion(
        imageBytes: imageBytes,
        contentType: contentType,
        idempotencyKey: idempotencyKeyFactory(),
      );
      return response.toEntity();
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
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() {
    return localDataSource.loadSampleSolution();
  }

  @override
  Future<QuestProfile> loadQuestProfile() {
    return localDataSource.loadQuestProfile();
  }
}

String _newIdempotencyKey() => const Uuid().v4();
