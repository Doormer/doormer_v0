import 'dart:convert';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:flutter/services.dart';

abstract class QuestionsLocalDataSource {
  Future<PhotoQuestionSolveOutcome> loadSampleSolution();

  Future<QuestProfile> loadQuestProfile();
}

/// Temporary bridge. The solve response only arrives via
/// `POST /v1/questions/photo`, so a page opened directly by URL has no data.
/// Serve the bundled sample until `GET /v1/questions/{id}` exists.
class QuestionsLocalDataSourceImpl implements QuestionsLocalDataSource {
  static const String mockAssetPath = 'assets/mock/mock_question_response.json';

  final AssetBundle _bundle;

  QuestionsLocalDataSourceImpl({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() async {
    try {
      final raw = await _bundle.loadString(mockAssetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PhotoQuestionResponseModel.fromJson(decoded).toEntity();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Sample solution asset load failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseFailure('We could not open the sample solution.');
    }
  }

  /// Mock standing. No endpoint serves XP, streaks or syllabus placement yet;
  /// replace this body with the remote call when one does.
  @override
  Future<QuestProfile> loadQuestProfile() async {
    return const QuestProfile(
      bankedXp: 120,
      streakDays: 3,
      topic: 'Geometry - Area',
      questionTitle: 'Road through a field',
    );
  }
}
