import 'dart:typed_data';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question_analysis.dart';

/// Abstract repository for mistake mirror functionality
abstract class MistakeMirrorRepository {
  /// Uploads a question image and processes it to get analysis with similar questions
  Future<QuestionAnalysis> analyzeQuestion(
    Uint8List imageBytes,
    String fileName,
  );

  /// Gets detailed solution for a specific question
  Future<Question> getQuestionDetails(String questionId);

  /// Saves user interaction with questions for analytics
  Future<void> recordQuestionInteraction(
    String questionId,
    String interactionType,
  );

  /// Gets user's question history
  Future<List<QuestionAnalysis>> getQuestionHistory();

  /// Bookmarks a question for later reference
  Future<void> bookmarkQuestion(String questionId);

  /// Gets bookmarked questions
  Future<List<Question>> getBookmarkedQuestions();
}
