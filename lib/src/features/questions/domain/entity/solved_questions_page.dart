import 'package:equatable/equatable.dart';

import 'solved_question_summary.dart';

/// One page of the student's solved questions, newest first.
class SolvedQuestionsPage extends Equatable {
  final List<SolvedQuestionSummary> questions;

  /// Where the next page starts. Null when there are no more.
  final String? nextCursor;

  const SolvedQuestionsPage({required this.questions, this.nextCursor});

  @override
  List<Object?> get props => [questions, nextCursor];
}
