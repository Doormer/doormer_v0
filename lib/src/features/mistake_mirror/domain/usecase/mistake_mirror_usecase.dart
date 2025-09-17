import 'dart:typed_data';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question_analysis.dart';
import 'package:doormer/src/features/mistake_mirror/domain/repository/mistake_mirror_repository.dart';

/// Main use case wrapper for mistake mirror functionality
class MistakeMirrorUseCase {
  final AnalyzeQuestionUseCase analyzeQuestion;
  final GetQuestionDetailsUseCase getQuestionDetails;
  final RecordInteractionUseCase recordInteraction;
  final GetQuestionHistoryUseCase getQuestionHistory;
  final BookmarkQuestionUseCase bookmarkQuestion;
  final GetBookmarkedQuestionsUseCase getBookmarkedQuestions;

  MistakeMirrorUseCase(MistakeMirrorRepository repository)
      : analyzeQuestion = AnalyzeQuestionUseCase(repository),
        getQuestionDetails = GetQuestionDetailsUseCase(repository),
        recordInteraction = RecordInteractionUseCase(repository),
        getQuestionHistory = GetQuestionHistoryUseCase(repository),
        bookmarkQuestion = BookmarkQuestionUseCase(repository),
        getBookmarkedQuestions = GetBookmarkedQuestionsUseCase(repository);
}

/// Use case for analyzing uploaded question images
class AnalyzeQuestionUseCase {
  final MistakeMirrorRepository repository;

  AnalyzeQuestionUseCase(this.repository);

  Future<QuestionAnalysis> call({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    const tenMB = 10 * 1024 * 1024;
    if (imageBytes.length > tenMB) {
      throw Exception("File size too large. Maximum size is 10MB.");
    }

    // Validate file format based on filename
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];
    final fileExtension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(fileExtension)) {
      throw Exception(
          "Invalid file format. Supported formats: ${allowedExtensions.join(', ')}");
    }

    try {
      final analysis = await repository.analyzeQuestion(imageBytes, fileName);

      // Validate that we have at least 3 similar questions
      if (analysis.similarQuestions.length < 3) {
        throw Exception(
            "Insufficient similar questions found. Please try with a clearer image.");
      }

      return analysis;
    } catch (error) {
      throw Exception("Question analysis failed: $error");
    }
  }
}

/// Use case for getting detailed question information
class GetQuestionDetailsUseCase {
  final MistakeMirrorRepository repository;

  GetQuestionDetailsUseCase(this.repository);

  Future<Question> call(String questionId) async {
    try {
      return await repository.getQuestionDetails(questionId);
    } catch (error) {
      throw Exception("Failed to get question details: $error");
    }
  }
}

/// Use case for recording user interactions
class RecordInteractionUseCase {
  final MistakeMirrorRepository repository;

  RecordInteractionUseCase(this.repository);

  Future<void> call({
    required String questionId,
    required String interactionType,
  }) async {
    try {
      await repository.recordQuestionInteraction(questionId, interactionType);
    } catch (error) {
      // Don't throw for analytics failures, just log
      print("Failed to record interaction: $error");
    }
  }
}

/// Use case for getting user's question history
class GetQuestionHistoryUseCase {
  final MistakeMirrorRepository repository;

  GetQuestionHistoryUseCase(this.repository);

  Future<List<QuestionAnalysis>> call() async {
    try {
      return await repository.getQuestionHistory();
    } catch (error) {
      throw Exception("Failed to get question history: $error");
    }
  }
}

/// Use case for bookmarking questions
class BookmarkQuestionUseCase {
  final MistakeMirrorRepository repository;

  BookmarkQuestionUseCase(this.repository);

  Future<void> call(String questionId) async {
    try {
      await repository.bookmarkQuestion(questionId);
    } catch (error) {
      throw Exception("Failed to bookmark question: $error");
    }
  }
}

/// Use case for getting bookmarked questions
class GetBookmarkedQuestionsUseCase {
  final MistakeMirrorRepository repository;

  GetBookmarkedQuestionsUseCase(this.repository);

  Future<List<Question>> call() async {
    try {
      return await repository.getBookmarkedQuestions();
    } catch (error) {
      throw Exception("Failed to get bookmarked questions: $error");
    }
  }
}
