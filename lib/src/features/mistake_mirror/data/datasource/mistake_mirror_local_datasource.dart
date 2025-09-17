import 'dart:convert';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/mistake_mirror/data/model/question_analysis_model.dart';
import 'package:doormer/src/features/mistake_mirror/data/model/question_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MistakeMirrorLocalDataSource {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  static const String _historyKey = 'mistake_mirror_history';
  static const String _bookmarksKey = 'mistake_mirror_bookmarks';

  /// Saves question analysis to local history
  Future<void> saveQuestionAnalysis(QuestionAnalysisModel analysis) async {
    try {
      final history = await getQuestionHistory();
      history.insert(0, analysis); // Add to beginning

      // Keep only last 50 items
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      final historyJson = history.map((a) => a.toJson()).toList();
      await secureStorage.write(
        key: _historyKey,
        value: jsonEncode(historyJson),
      );

      AppLogger.info('Question analysis saved to local history');
    } catch (error) {
      AppLogger.error('Error saving question analysis: $error');
    }
  }

  /// Gets question history from local storage
  Future<List<QuestionAnalysisModel>> getQuestionHistory() async {
    try {
      final historyString = await secureStorage.read(key: _historyKey);
      if (historyString == null) return [];

      final List<dynamic> historyJson = jsonDecode(historyString);
      return historyJson
          .map((json) => QuestionAnalysisModel.fromJson(json))
          .toList();
    } catch (error) {
      AppLogger.error('Error getting question history: $error');
      return [];
    }
  }

  /// Saves a bookmarked question
  Future<void> bookmarkQuestion(QuestionModel question) async {
    try {
      final bookmarks = await getBookmarkedQuestions();

      // Check if already bookmarked
      if (bookmarks.any((q) => q.id == question.id)) {
        AppLogger.info('Question already bookmarked: ${question.id}');
        return;
      }

      bookmarks.add(question);

      final bookmarksJson = bookmarks.map((q) => q.toJson()).toList();
      await secureStorage.write(
        key: _bookmarksKey,
        value: jsonEncode(bookmarksJson),
      );

      AppLogger.info('Question bookmarked locally: ${question.id}');
    } catch (error) {
      AppLogger.error('Error bookmarking question: $error');
    }
  }

  /// Gets bookmarked questions from local storage
  Future<List<QuestionModel>> getBookmarkedQuestions() async {
    try {
      final bookmarksString = await secureStorage.read(key: _bookmarksKey);
      if (bookmarksString == null) return [];

      final List<dynamic> bookmarksJson = jsonDecode(bookmarksString);
      return bookmarksJson.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (error) {
      AppLogger.error('Error getting bookmarked questions: $error');
      return [];
    }
  }

  /// Removes a bookmark
  Future<void> removeBookmark(String questionId) async {
    try {
      final bookmarks = await getBookmarkedQuestions();
      bookmarks.removeWhere((q) => q.id == questionId);

      final bookmarksJson = bookmarks.map((q) => q.toJson()).toList();
      await secureStorage.write(
        key: _bookmarksKey,
        value: jsonEncode(bookmarksJson),
      );

      AppLogger.info('Bookmark removed: $questionId');
    } catch (error) {
      AppLogger.error('Error removing bookmark: $error');
    }
  }

  /// Clears all local data
  Future<void> clearAllData() async {
    try {
      await secureStorage.delete(key: _historyKey);
      await secureStorage.delete(key: _bookmarksKey);
      AppLogger.info('All local mistake mirror data cleared');
    } catch (error) {
      AppLogger.error('Error clearing local data: $error');
    }
  }
}
