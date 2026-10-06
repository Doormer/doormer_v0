import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';

/// The body of `POST /v1/questions/solved`.
class SolvedQuestionsResponseModel {
  final List<SolvedQuestionSummaryModel> questions;
  final String? nextCursor;

  const SolvedQuestionsResponseModel({
    required this.questions,
    this.nextCursor,
  });

  factory SolvedQuestionsResponseModel.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];
    if (questions is! List) {
      throw const FormatException(
          'Solved questions response has no list of questions');
    }
    return SolvedQuestionsResponseModel(
      questions: [
        for (final question in questions)
          SolvedQuestionSummaryModel.fromJson(question as Map<String, dynamic>),
      ],
      nextCursor: _nonEmpty(json['next_cursor']),
    );
  }

  SolvedQuestionsPage toEntity() => SolvedQuestionsPage(
        questions: [for (final question in questions) question.toEntity()],
        nextCursor: nextCursor,
      );
}

/// One row of `POST /v1/questions/solved`.
class SolvedQuestionSummaryModel {
  final String questionId;
  final String topic;
  final String method;
  final String questionText;
  final DateTime askedAt;
  final String? thumbnailUrl;
  final String? photoUrl;

  const SolvedQuestionSummaryModel({
    required this.questionId,
    required this.topic,
    required this.method,
    required this.questionText,
    required this.askedAt,
    this.thumbnailUrl,
    this.photoUrl,
  });

  factory SolvedQuestionSummaryModel.fromJson(Map<String, dynamic> json) {
    final questionId = json['question_id']?.toString() ?? '';
    if (questionId.isEmpty) {
      throw const FormatException('Solved question has no question_id');
    }
    final askedAt = DateTime.tryParse(json['asked_at']?.toString() ?? '');
    if (askedAt == null) {
      throw const FormatException('Solved question has no readable asked_at');
    }
    return SolvedQuestionSummaryModel(
      questionId: questionId,
      topic: json['topic']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      questionText: json['question_text']?.toString() ?? '',
      askedAt: askedAt,
      thumbnailUrl: _nonEmpty(json['thumbnail_url']),
      photoUrl: _nonEmpty(json['photo_url']),
    );
  }

  SolvedQuestionSummary toEntity() => SolvedQuestionSummary(
        questionId: questionId,
        topic: topic,
        method: method,
        questionText: questionText,
        askedAt: askedAt,
        thumbnailUrl: thumbnailUrl,
        photoUrl: photoUrl,
      );
}

/// A text field, or null when it is missing or empty. The API leaves out a
/// thumbnail it has none of, and sends an empty photo link it could not sign.
String? _nonEmpty(Object? value) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? null : text;
}
