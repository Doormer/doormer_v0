import 'package:equatable/equatable.dart';

import 'shared_question_summary.dart';

/// One page of the questions friends shared with the student, newest share
/// first.
class SharedQuestionsPage extends Equatable {
  final List<SharedQuestionSummary> questions;

  /// Where the next page starts, as the API gave it, to be sent back as it
  /// is. Null when there are no more.
  final String? nextCursor;

  const SharedQuestionsPage({required this.questions, this.nextCursor});

  @override
  List<Object?> get props => [questions, nextCursor];
}
