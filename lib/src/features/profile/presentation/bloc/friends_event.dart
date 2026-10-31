part of 'friends_bloc.dart';

sealed class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => const [];
}

/// Profile opened.
class FriendsStarted extends FriendsEvent {
  const FriendsStarted();
}

/// The student tapped Try again.
class FriendsRetried extends FriendsEvent {
  const FriendsRetried();
}

/// The student came back to Profile, where requests may have arrived, or
/// came back from a page under it, where they may have changed something.
class FriendsRefreshRequested extends FriendsEvent {
  const FriendsRefreshRequested();
}

/// The student tapped Accept on a request.
class FriendRequestAccepted extends FriendsEvent {
  final String requestId;

  const FriendRequestAccepted(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// The student tapped Decline on a request.
class FriendRequestDeclined extends FriendsEvent {
  final String requestId;

  const FriendRequestDeclined(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// The student chose Remove on a friend.
class FriendRemoved extends FriendsEvent {
  final String friendId;

  const FriendRemoved(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// The student chose Block on a friend, on a request, or in the report sheet.
class StudentBlocked extends FriendsEvent {
  final String friendId;

  const StudentBlocked(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// The report sheet opened for a student, so their report starts unsent.
class ReportOpened extends FriendsEvent {
  final String friendId;

  const ReportOpened(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// The student sent a report from the report sheet.
class StudentReported extends FriendsEvent {
  final String friendId;
  final ReportReason reason;

  /// Empty when the student wrote none.
  final String note;

  const StudentReported({
    required this.friendId,
    required this.reason,
    required this.note,
  });

  @override
  List<Object?> get props => [friendId, reason, note];
}
