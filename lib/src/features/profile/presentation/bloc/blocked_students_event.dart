part of 'blocked_students_bloc.dart';

sealed class BlockedStudentsEvent extends Equatable {
  const BlockedStudentsEvent();

  @override
  List<Object?> get props => const [];
}

/// The Blocked students page opened.
class BlockedStudentsStarted extends BlockedStudentsEvent {
  const BlockedStudentsStarted();
}

/// The student tapped Try again.
class BlockedStudentsRetried extends BlockedStudentsEvent {
  const BlockedStudentsRetried();
}

/// The student tapped Unblock on a row.
class StudentUnblocked extends BlockedStudentsEvent {
  final String friendId;

  const StudentUnblocked(this.friendId);

  @override
  List<Object?> get props => [friendId];
}
