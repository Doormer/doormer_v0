import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:equatable/equatable.dart';

import 'solved_question_summary.dart';

/// A question a friend asked and shared with the student, as Shared with me
/// lists it.
class SharedQuestionSummary extends Equatable {
  /// The question, as a row of Saved shows it.
  final SolvedQuestionSummary question;

  /// The friend who shared it.
  final FriendSummary sharedBy;

  final DateTime sharedAt;

  const SharedQuestionSummary({
    required this.question,
    required this.sharedBy,
    required this.sharedAt,
  });

  @override
  List<Object?> get props => [question, sharedBy, sharedAt];
}
