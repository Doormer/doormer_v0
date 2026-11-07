import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';

import '../../domain/entity/shared_question_summary.dart';
import '../../domain/entity/shared_questions_page.dart';
import 'solved_questions_response_model.dart';

/// The body of `POST /v1/questions/shared`.
class SharedQuestionsResponseModel {
  final List<SharedQuestionSummaryModel> questions;
  final String? nextCursor;

  const SharedQuestionsResponseModel({
    required this.questions,
    this.nextCursor,
  });

  factory SharedQuestionsResponseModel.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];
    if (questions is! List) {
      throw const FormatException(
          'Shared questions response has no list of questions');
    }
    // Left out on the last page.
    final nextCursor = json['next_cursor']?.toString() ?? '';
    return SharedQuestionsResponseModel(
      questions: [
        for (final question in questions)
          SharedQuestionSummaryModel.fromJson(question as Map<String, dynamic>),
      ],
      nextCursor: nextCursor.isEmpty ? null : nextCursor,
    );
  }

  SharedQuestionsPage toEntity() => SharedQuestionsPage(
        questions: [for (final question in questions) question.toEntity()],
        nextCursor: nextCursor,
      );
}

/// One row of `POST /v1/questions/shared`: a solved question's fields, and
/// who shared it and when, all at one level.
class SharedQuestionSummaryModel {
  final SolvedQuestionSummaryModel question;
  final FriendSummaryModel sharedBy;
  final DateTime sharedAt;

  const SharedQuestionSummaryModel({
    required this.question,
    required this.sharedBy,
    required this.sharedAt,
  });

  factory SharedQuestionSummaryModel.fromJson(Map<String, dynamic> json) {
    final sharedBy = json['shared_by'];
    if (sharedBy is! Map<String, dynamic>) {
      throw const FormatException('Shared question has no shared_by');
    }
    final sharedAt = DateTime.tryParse(json['shared_at']?.toString() ?? '');
    if (sharedAt == null) {
      throw const FormatException('Shared question has no readable shared_at');
    }
    return SharedQuestionSummaryModel(
      question: SolvedQuestionSummaryModel.fromJson(json),
      sharedBy: FriendSummaryModel.fromJson(sharedBy),
      sharedAt: sharedAt,
    );
  }

  SharedQuestionSummary toEntity() => SharedQuestionSummary(
        question: question.toEntity(),
        sharedBy: sharedBy.toEntity(),
        sharedAt: sharedAt,
      );
}
