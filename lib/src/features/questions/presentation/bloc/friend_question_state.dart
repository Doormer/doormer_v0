part of 'friend_question_bloc.dart';

enum QuestionReportStatus { unsent, sending, sent }

/// Why the reader closes: the question has left the student's Shared with
/// me.
enum FriendQuestionExit { removed, blocked }

/// A question a friend shared with the student, and what the student is
/// doing about it.
class FriendQuestionState extends Equatable {
  /// Empty until the reader has opened the question.
  final String questionId;

  /// The friend who shared the question. Null until the reader has opened it.
  final FriendSummary? sharedBy;

  final bool isRemoving;
  final QuestionReportStatus reportStatus;
  final bool isBlocking;

  /// Set once the question has gone, and the reader should close.
  final FriendQuestionExit? exit;

  /// Why the last action failed. Only the state that failed carries it.
  final String? errorMessage;

  const FriendQuestionState({
    this.questionId = '',
    this.sharedBy,
    this.isRemoving = false,
    this.reportStatus = QuestionReportStatus.unsent,
    this.isBlocking = false,
    this.exit,
    this.errorMessage,
  });

  /// A copy with the changes given. [errorMessage] is left out unless given,
  /// so it is said once.
  FriendQuestionState copyWith({
    bool? isRemoving,
    QuestionReportStatus? reportStatus,
    bool? isBlocking,
    FriendQuestionExit? exit,
    String? errorMessage,
  }) {
    return FriendQuestionState(
      questionId: questionId,
      sharedBy: sharedBy,
      isRemoving: isRemoving ?? this.isRemoving,
      reportStatus: reportStatus ?? this.reportStatus,
      isBlocking: isBlocking ?? this.isBlocking,
      exit: exit ?? this.exit,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        questionId,
        sharedBy,
        isRemoving,
        reportStatus,
        isBlocking,
        exit,
        errorMessage,
      ];
}
