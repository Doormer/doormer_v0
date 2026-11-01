part of 'share_question_bloc.dart';

/// What just finished, for the page to say once.
enum ShareNotice { shared, stopped }

/// The student's own question: who it is shared with, the sheet of friends
/// to send it to, and whether Stop sharing is on its way.
class ShareQuestionState extends Equatable {
  /// Empty until the reader has opened the question.
  final String questionId;

  /// Every friend the question is shared with, by nickname.
  final List<FriendSummary> sharedWith;

  final ShareSheet sheet;

  final bool isStopping;

  /// What just finished. Only the state that finished it carries it.
  final ShareNotice? notice;

  /// Why the last action failed. Only the state that failed carries it.
  final String? errorMessage;

  const ShareQuestionState({
    this.questionId = '',
    this.sharedWith = const [],
    this.sheet = const ShareSheetClosed(),
    this.isStopping = false,
    this.notice,
    this.errorMessage,
  });

  bool isSharedWith(String friendId) =>
      sharedWith.any((friend) => friend.friendId == friendId);

  /// A copy with the changes given. [notice] and [errorMessage] are left out
  /// unless given, so each is said once.
  ShareQuestionState copyWith({
    List<FriendSummary>? sharedWith,
    ShareSheet? sheet,
    bool? isStopping,
    ShareNotice? notice,
    String? errorMessage,
  }) {
    return ShareQuestionState(
      questionId: questionId,
      sharedWith: sharedWith ?? this.sharedWith,
      sheet: sheet ?? this.sheet,
      isStopping: isStopping ?? this.isStopping,
      notice: notice,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [questionId, sharedWith, sheet, isStopping, notice, errorMessage];
}

/// What the sheet of friends shows.
sealed class ShareSheet extends Equatable {
  const ShareSheet();

  @override
  List<Object?> get props => const [];
}

/// The sheet is closed, or has just sent.
class ShareSheetClosed extends ShareSheet {
  const ShareSheetClosed();
}

class ShareSheetLoading extends ShareSheet {
  const ShareSheetLoading();
}

/// There is no one to share with: no friends yet, no friend profile yet, or
/// friends turned off. [message] says which.
class ShareSheetUnavailable extends ShareSheet {
  final String message;

  const ShareSheetUnavailable(this.message);

  @override
  List<Object?> get props => [message];
}

/// The friends could not load. The sheet offers Try again.
class ShareSheetError extends ShareSheet {
  final String message;

  const ShareSheetError(this.message);

  @override
  List<Object?> get props => [message];
}

class ShareSheetReady extends ShareSheet {
  /// The student's friends, by nickname.
  final List<FriendSummary> friends;

  /// The IDs of the friends ticked to send to. Never a friend the question is
  /// already shared with.
  final Set<String> ticked;

  final bool isSending;

  const ShareSheetReady({
    required this.friends,
    this.ticked = const {},
    this.isSending = false,
  });

  /// As many friends are ticked as one send takes.
  bool get isFull => ticked.length >= ShareQuestionBloc.maxFriendsPerSend;

  ShareSheetReady copyWith({Set<String>? ticked, bool? isSending}) {
    return ShareSheetReady(
      friends: friends,
      ticked: ticked ?? this.ticked,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [friends, ticked, isSending];
}
