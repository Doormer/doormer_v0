part of 'share_question_bloc.dart';

sealed class ShareQuestionEvent extends Equatable {
  const ShareQuestionEvent();

  @override
  List<Object?> get props => const [];
}

/// The reader opened the student's own question, which is shared with
/// [sharedWith].
class ShareQuestionStarted extends ShareQuestionEvent {
  final String questionId;
  final List<FriendSummary> sharedWith;

  const ShareQuestionStarted({
    required this.questionId,
    required this.sharedWith,
  });

  @override
  List<Object?> get props => [questionId, sharedWith];
}

/// The student tapped Share, or Try again in the sheet.
class ShareSheetOpened extends ShareQuestionEvent {
  const ShareSheetOpened();
}

/// The student ticked or unticked a friend in the sheet.
class ShareFriendToggled extends ShareQuestionEvent {
  final String friendId;

  const ShareFriendToggled(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// The student tapped Send.
class ShareSent extends ShareQuestionEvent {
  const ShareSent();
}

/// The student confirmed Stop sharing.
class SharingStopped extends ShareQuestionEvent {
  const SharingStopped();
}
