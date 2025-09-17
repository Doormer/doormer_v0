import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/mistake_mirror/data/model/question_analysis_model.dart';
import 'package:doormer/src/features/mistake_mirror/data/model/question_model.dart';

class MistakeMirrorRemoteDataSource {
  final Dio dio;

  MistakeMirrorRemoteDataSource({required this.dio});

  /// Uploads question image and gets analysis
  Future<QuestionAnalysisModel> analyzeQuestion(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      AppLogger.info('Analyzing question image: $fileName');

      // Create multipart form data
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/api/mistake-mirror/analyze',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Question analysis successful');
        return QuestionAnalysisModel.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to analyze question: ${response.statusMessage}');
      }
    } catch (error) {
      AppLogger.error('Error analyzing question: $error');
      rethrow;
    }
  }

  /// Gets detailed question information
  Future<QuestionModel> getQuestionDetails(String questionId) async {
    try {
      AppLogger.info('Getting question details for: $questionId');

      final response =
          await dio.get('/api/mistake-mirror/question/$questionId');

      if (response.statusCode == 200) {
        AppLogger.info('Question details retrieved successfully');
        return QuestionModel.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to get question details: ${response.statusMessage}');
      }
    } catch (error) {
      AppLogger.error('Error getting question details: $error');
      rethrow;
    }
  }

  /// Records user interaction with questions
  Future<void> recordQuestionInteraction(
    String questionId,
    String interactionType,
  ) async {
    try {
      AppLogger.info('Recording interaction: $questionId - $interactionType');

      await dio.post('/api/mistake-mirror/interaction', data: {
        'question_id': questionId,
        'interaction_type': interactionType,
        'timestamp': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Interaction recorded successfully');
    } catch (error) {
      AppLogger.error('Error recording interaction: $error');
      // Don't rethrow for analytics failures
    }
  }

  /// Gets user's question history
  Future<List<QuestionAnalysisModel>> getQuestionHistory() async {
    try {
      AppLogger.info('Getting question history');

      final response = await dio.get('/api/mistake-mirror/history');

      if (response.statusCode == 200) {
        AppLogger.info('Question history retrieved successfully');
        final List<dynamic> historyData = response.data['data'];
        return historyData
            .map((json) => QuestionAnalysisModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to get question history: ${response.statusMessage}');
      }
    } catch (error) {
      AppLogger.error('Error getting question history: $error');
      rethrow;
    }
  }

  /// Bookmarks a question
  Future<void> bookmarkQuestion(String questionId) async {
    try {
      AppLogger.info('Bookmarking question: $questionId');

      await dio.post('/api/mistake-mirror/bookmark', data: {
        'question_id': questionId,
      });

      AppLogger.info('Question bookmarked successfully');
    } catch (error) {
      AppLogger.error('Error bookmarking question: $error');
      rethrow;
    }
  }

  /// Gets bookmarked questions
  Future<List<QuestionModel>> getBookmarkedQuestions() async {
    try {
      AppLogger.info('Getting bookmarked questions');

      final response = await dio.get('/api/mistake-mirror/bookmarks');

      if (response.statusCode == 200) {
        AppLogger.info('Bookmarked questions retrieved successfully');
        final List<dynamic> bookmarksData = response.data['data'];
        return bookmarksData
            .map((json) => QuestionModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to get bookmarked questions: ${response.statusMessage}');
      }
    } catch (error) {
      AppLogger.error('Error getting bookmarked questions: $error');
      rethrow;
    }
  }
}
