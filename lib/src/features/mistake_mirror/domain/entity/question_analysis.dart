import 'dart:typed_data';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';

class QuestionAnalysis {
  final String originalQuestionId;
  final String questionType;
  final String detectedTopic;
  final String difficulty;
  final List<Question> similarQuestions;
  final List<String> suggestedTopics;
  final double confidenceScore;

  QuestionAnalysis({
    required this.originalQuestionId,
    required this.questionType,
    required this.detectedTopic,
    required this.difficulty,
    required this.similarQuestions,
    required this.suggestedTopics,
    required this.confidenceScore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAnalysis &&
          runtimeType == other.runtimeType &&
          originalQuestionId == other.originalQuestionId;

  @override
  int get hashCode => originalQuestionId.hashCode;
}

class UploadedQuestion {
  final String tempId;
  final Uint8List imageBytes;
  final String fileName;
  final DateTime uploadTime;

  UploadedQuestion({
    required this.tempId,
    required this.imageBytes,
    required this.fileName,
    required this.uploadTime,
  });
}
