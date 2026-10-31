part of 'blocked_students_bloc.dart';

sealed class BlockedStudentsState extends Equatable {
  const BlockedStudentsState();

  @override
  List<Object?> get props => const [];
}

class BlockedStudentsLoading extends BlockedStudentsState {
  const BlockedStudentsLoading();
}

class BlockedStudentsError extends BlockedStudentsState {
  final String message;

  const BlockedStudentsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BlockedStudentsReady extends BlockedStudentsState {
  /// Newest block first.
  final List<FriendSummary> students;

  /// Students with an Unblock on its way.
  final Set<String> unblockingIds;

  /// Set once when an Unblock fails, so the page can say why. Cleared by the
  /// next change of state.
  final String? errorMessage;

  const BlockedStudentsReady({
    required this.students,
    this.unblockingIds = const {},
    this.errorMessage,
  });

  BlockedStudentsReady copyWith({Set<String>? unblockingIds}) {
    return BlockedStudentsReady(
      students: students,
      unblockingIds: unblockingIds ?? this.unblockingIds,
    );
  }

  @override
  List<Object?> get props => [students, unblockingIds, errorMessage];
}
