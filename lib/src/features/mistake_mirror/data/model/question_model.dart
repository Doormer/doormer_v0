import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';

class QuestionModel {
  final String id;
  final String questionText;
  final String? imageUrl;
  final String questionType;
  final List<String> stepByStepSolution;
  final String answer;
  final String difficulty;
  final List<String> tags;

  QuestionModel({
    required this.id,
    required this.questionText,
    this.imageUrl,
    required this.questionType,
    required this.stepByStepSolution,
    required this.answer,
    required this.difficulty,
    required this.tags,
  });

  /// Creates a QuestionModel from JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      questionText: json['question_text'] as String,
      imageUrl: json['image_url'] as String?,
      questionType: json['question_type'] as String,
      stepByStepSolution:
          List<String>.from(json['step_by_step_solution'] ?? []),
      answer: json['answer'] as String,
      difficulty: json['difficulty'] as String,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// Converts QuestionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'image_url': imageUrl,
      'question_type': questionType,
      'step_by_step_solution': stepByStepSolution,
      'answer': answer,
      'difficulty': difficulty,
      'tags': tags,
    };
  }

  /// Converts QuestionModel to domain entity
  Question toEntity() {
    return Question(
      id: id,
      questionText: questionText,
      imageUrl: imageUrl,
      questionType: questionType,
      stepByStepSolution: stepByStepSolution,
      answer: answer,
      difficulty: difficulty,
      tags: tags,
    );
  }

  /// Creates QuestionModel from domain entity
  factory QuestionModel.fromEntity(Question question) {
    return QuestionModel(
      id: question.id,
      questionText: question.questionText,
      imageUrl: question.imageUrl,
      questionType: question.questionType,
      stepByStepSolution: question.stepByStepSolution,
      answer: question.answer,
      difficulty: question.difficulty,
      tags: question.tags,
    );
  }
}
