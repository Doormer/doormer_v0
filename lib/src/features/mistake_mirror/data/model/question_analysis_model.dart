import 'package:doormer/src/features/mistake_mirror/data/model/question_model.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question_analysis.dart';

class QuestionAnalysisModel {
  final String originalQuestionId;
  final String questionType;
  final String detectedTopic;
  final String difficulty;
  final List<QuestionModel> similarQuestions;
  final List<String> suggestedTopics;
  final double confidenceScore;

  QuestionAnalysisModel({
    required this.originalQuestionId,
    required this.questionType,
    required this.detectedTopic,
    required this.difficulty,
    required this.similarQuestions,
    required this.suggestedTopics,
    required this.confidenceScore,
  });

  /// Creates QuestionAnalysisModel from JSON
  factory QuestionAnalysisModel.fromJson(Map<String, dynamic> json) {
    return QuestionAnalysisModel(
      originalQuestionId: json['original_question_id'] as String,
      questionType: json['question_type'] as String,
      detectedTopic: json['detected_topic'] as String,
      difficulty: json['difficulty'] as String,
      similarQuestions: (json['similar_questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      suggestedTopics: List<String>.from(json['suggested_topics'] ?? []),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
    );
  }

  /// Converts QuestionAnalysisModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'original_question_id': originalQuestionId,
      'question_type': questionType,
      'detected_topic': detectedTopic,
      'difficulty': difficulty,
      'similar_questions': similarQuestions.map((q) => q.toJson()).toList(),
      'suggested_topics': suggestedTopics,
      'confidence_score': confidenceScore,
    };
  }

  /// Converts QuestionAnalysisModel to domain entity
  QuestionAnalysis toEntity() {
    return QuestionAnalysis(
      originalQuestionId: originalQuestionId,
      questionType: questionType,
      detectedTopic: detectedTopic,
      difficulty: difficulty,
      similarQuestions: similarQuestions.map((q) => q.toEntity()).toList(),
      suggestedTopics: suggestedTopics,
      confidenceScore: confidenceScore,
    );
  }

  /// Creates QuestionAnalysisModel from domain entity
  factory QuestionAnalysisModel.fromEntity(QuestionAnalysis analysis) {
    return QuestionAnalysisModel(
      originalQuestionId: analysis.originalQuestionId,
      questionType: analysis.questionType,
      detectedTopic: analysis.detectedTopic,
      difficulty: analysis.difficulty,
      similarQuestions: analysis.similarQuestions
          .map((q) => QuestionModel.fromEntity(q))
          .toList(),
      suggestedTopics: analysis.suggestedTopics,
      confidenceScore: analysis.confidenceScore,
    );
  }
}
