part of 'friend_question_bloc.dart';

sealed class FriendQuestionEvent extends Equatable {
  const FriendQuestionEvent();

  @override
  List<Object?> get props => const [];
}

/// The reader opened a question [sharedBy] shared with the student.
class FriendQuestionStarted extends FriendQuestionEvent {
  final String questionId;
  final FriendSummary sharedBy;

  const FriendQuestionStarted({
    required this.questionId,
    required this.sharedBy,
  });

  @override
  List<Object?> get props => [questionId, sharedBy];
}

/// The student confirmed Remove.
class SharedQuestionRemoved extends FriendQuestionEvent {
  const SharedQuestionRemoved();
}

/// The student opened the report sheet.
class SharedQuestionReportOpened extends FriendQuestionEvent {
  const SharedQuestionReportOpened();
}

/// The student sent a report on the friend, with the question. [note] is
/// trimmed, and empty when they wrote none.
class SharedQuestionReported extends FriendQuestionEvent {
  final ReportReason reason;
  final String note;

  const SharedQuestionReported({required this.reason, required this.note});

  @override
  List<Object?> get props => [reason, note];
}

/// The student confirmed Block on the friend who shared the question.
class FriendBlocked extends FriendQuestionEvent {
  const FriendBlocked();
}
