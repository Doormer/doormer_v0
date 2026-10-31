part of 'add_friend_bloc.dart';

sealed class AddFriendEvent extends Equatable {
  const AddFriendEvent();

  @override
  List<Object?> get props => const [];
}

/// Add a friend opened, or the student tapped Try again.
class AddFriendStarted extends AddFriendEvent {
  /// The friend code of the invite link it was opened from. Null when it
  /// was opened from Profile.
  final String? inviteCode;

  const AddFriendStarted({this.inviteCode});

  @override
  List<Object?> get props => [inviteCode];
}

/// The student tapped Find.
class FriendCodeSubmitted extends AddFriendEvent {
  /// As typed: any case, with or without spaces and dashes.
  final String typed;

  const FriendCodeSubmitted(this.typed);

  @override
  List<Object?> get props => [typed];
}

/// The student tapped Send request, or Accept, on the found student.
class FriendRequestSent extends AddFriendEvent {
  const FriendRequestSent();
}

/// The student tapped Unblock on the found student.
class FoundStudentUnblocked extends AddFriendEvent {
  const FoundStudentUnblocked();
}

/// The student confirmed Reset code.
class FriendCodeReset extends AddFriendEvent {
  const FriendCodeReset();
}
