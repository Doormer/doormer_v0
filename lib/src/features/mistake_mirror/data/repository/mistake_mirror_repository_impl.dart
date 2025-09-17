import 'dart:typed_data';
import 'package:doormer/src/features/mistake_mirror/data/datasource/mistake_mirror_local_datasource.dart';
import 'package:doormer/src/features/mistake_mirror/data/datasource/mistake_mirror_remote_datasource.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question_analysis.dart';
import 'package:doormer/src/features/mistake_mirror/domain/repository/mistake_mirror_repository.dart';

/// Implementation of MistakeMirrorRepository that uses remote and local data sources
class MistakeMirrorRepositoryImpl implements MistakeMirrorRepository {
  final MistakeMirrorRemoteDataSource _remoteDataSource;
  final MistakeMirrorLocalDataSource _localDataSource;

  MistakeMirrorRepositoryImpl({
    required MistakeMirrorRemoteDataSource remoteDataSource,
    required MistakeMirrorLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<QuestionAnalysis> analyzeQuestion(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Analyze question using remote data source
      final analysisModel = await _remoteDataSource.analyzeQuestion(
        imageBytes,
        fileName,
      );

      // Save analysis to local history
      await _localDataSource.saveQuestionAnalysis(analysisModel);

      // Convert to domain entity and return
      return analysisModel.toEntity();
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<Question> getQuestionDetails(String questionId) async {
    try {
      // Get question details from remote data source
      final questionModel =
          await _remoteDataSource.getQuestionDetails(questionId);

      // Convert to domain entity and return
      return questionModel.toEntity();
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<void> recordQuestionInteraction(
    String questionId,
    String interactionType,
  ) async {
    // Record interaction with remote data source
    // Don't await to avoid blocking UI
    _remoteDataSource.recordQuestionInteraction(questionId, interactionType);
  }

  @override
  Future<List<QuestionAnalysis>> getQuestionHistory() async {
    try {
      // Try to get history from remote first
      final remoteHistory = await _remoteDataSource.getQuestionHistory();

      // Convert to domain entities
      return remoteHistory.map((model) => model.toEntity()).toList();
    } catch (error) {
      // Fall back to local history if remote fails
      final localHistory = await _localDataSource.getQuestionHistory();
      return localHistory.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<void> bookmarkQuestion(String questionId) async {
    try {
      // Get question details first
      final questionModel =
          await _remoteDataSource.getQuestionDetails(questionId);

      // Bookmark remotely
      await _remoteDataSource.bookmarkQuestion(questionId);

      // Save to local bookmarks as backup
      await _localDataSource.bookmarkQuestion(questionModel);
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<List<Question>> getBookmarkedQuestions() async {
    try {
      // Try to get bookmarks from remote first
      final remoteBookmarks = await _remoteDataSource.getBookmarkedQuestions();

      // Convert to domain entities
      return remoteBookmarks.map((model) => model.toEntity()).toList();
    } catch (error) {
      // Fall back to local bookmarks if remote fails
      final localBookmarks = await _localDataSource.getBookmarkedQuestions();
      return localBookmarks.map((model) => model.toEntity()).toList();
    }
  }
}
