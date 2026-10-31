import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecase/load_blocked_students_usecase.dart';
import '../../domain/usecase/unblock_student_usecase.dart';

part 'blocked_students_event.dart';
part 'blocked_students_state.dart';

/// The students the student has blocked, and unblocking them.
class BlockedStudentsBloc
    extends Bloc<BlockedStudentsEvent, BlockedStudentsState> {
  final LoadBlockedStudentsUseCase loadBlockedStudents;
  final UnblockStudentUseCase unblockStudent;

  BlockedStudentsBloc({
    required this.loadBlockedStudents,
    required this.unblockStudent,
  }) : super(const BlockedStudentsLoading()) {
    on<BlockedStudentsStarted>(_onStarted);
    on<BlockedStudentsRetried>(_onRetried);
    on<StudentUnblocked>(_onStudentUnblocked);
  }

  Future<void> _onStarted(
    BlockedStudentsStarted event,
    Emitter<BlockedStudentsState> emit,
  ) =>
      _load(emit);

  Future<void> _onRetried(
    BlockedStudentsRetried event,
    Emitter<BlockedStudentsState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<BlockedStudentsState> emit) async {
    if (state is! BlockedStudentsLoading) emit(const BlockedStudentsLoading());
    try {
      emit(BlockedStudentsReady(students: await loadBlockedStudents()));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Blocked students failed to load',
          error: f, stackTrace: stackTrace);
      emit(BlockedStudentsError(f.message));
    } catch (e, stackTrace) {
      AppLogger.error('Blocked students failed to load unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(const BlockedStudentsError(FriendsMessages.couldNotLoadBlocked));
    }
  }

  /// Unblocks one student. Their row waits for the answer, then goes.
  Future<void> _onStudentUnblocked(
    StudentUnblocked event,
    Emitter<BlockedStudentsState> emit,
  ) async {
    final ready = state;
    if (ready is! BlockedStudentsReady ||
        ready.unblockingIds.contains(event.friendId)) {
      return;
    }
    emit(ready.copyWith(
      unblockingIds: {...ready.unblockingIds, event.friendId},
    ));

    String? errorMessage;
    try {
      await unblockStudent(event.friendId);
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Unblocking a student failed',
          error: f, stackTrace: stackTrace);
      errorMessage = f.message;
    } catch (e, stackTrace) {
      AppLogger.error('Unblocking a student failed unexpectedly',
          error: e, stackTrace: stackTrace);
      errorMessage = FriendsMessages.somethingWentWrong;
    }

    final latest = state;
    if (latest is! BlockedStudentsReady) return;
    emit(BlockedStudentsReady(
      students: errorMessage == null
          ? [
              for (final student in latest.students)
                if (student.friendId != event.friendId) student,
            ]
          : latest.students,
      unblockingIds: {...latest.unblockingIds}..remove(event.friendId),
      errorMessage: errorMessage,
    ));
  }
}
