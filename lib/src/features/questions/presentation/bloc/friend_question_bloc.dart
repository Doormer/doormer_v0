import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecase/block_friend_usecase.dart';
import '../../domain/usecase/remove_shared_question_usecase.dart';
import '../../domain/usecase/report_shared_question_usecase.dart';

part 'friend_question_event.dart';
part 'friend_question_state.dart';

/// A question a friend shared with the student, open in the reader: Remove
/// it from Shared with me, Report the friend with it, and Block them.
///
/// Handlers run concurrently, so each applies its answer to the state as it
/// stands after the await, never to the one before it.
class FriendQuestionBloc
    extends Bloc<FriendQuestionEvent, FriendQuestionState> {
  final RemoveSharedQuestionUseCase removeSharedQuestion;
  final ReportSharedQuestionUseCase reportSharedQuestion;
  final BlockFriendUseCase blockFriend;

  /// Answers once the last report sent has its answer, however it went.
  Future<void> _reportAnswered = Future.value();

  FriendQuestionBloc({
    required this.removeSharedQuestion,
    required this.reportSharedQuestion,
    required this.blockFriend,
  }) : super(const FriendQuestionState()) {
    on<FriendQuestionStarted>(_onStarted);
    on<SharedQuestionRemoved>(_onRemoved);
    on<SharedQuestionReported>(_onReported);
    on<FriendBlocked>(_onFriendBlocked);
  }

  void _onStarted(
    FriendQuestionStarted event,
    Emitter<FriendQuestionState> emit,
  ) {
    emit(FriendQuestionState(
      questionId: event.questionId,
      sharedBy: event.sharedBy,
    ));
  }

  /// Takes the question out of Shared with me. That ends the share, and the
  /// API refuses a report about a share that has ended, so a report on its
  /// way gets its answer first.
  Future<void> _onRemoved(
    SharedQuestionRemoved event,
    Emitter<FriendQuestionState> emit,
  ) async {
    if (state.isRemoving || state.exit != null) return;
    emit(state.copyWith(isRemoving: true));
    await _reportAnswered;
    final failure = await _attempt(
      () => removeSharedQuestion(state.questionId),
      'Removing a shared question',
    );
    emit(failure == null
        ? state.copyWith(isRemoving: false, exit: FriendQuestionExit.removed)
        : state.copyWith(isRemoving: false, errorMessage: failure.message));
  }

  /// Sends the report with the question. The share must still stand when it
  /// arrives, so the sheet offers Block only after this, unless the report
  /// is refused for good, and a removal waits for it. A report sent while a
  /// removal is on its way could arrive after the share has ended, so it
  /// sends nothing.
  Future<void> _onReported(
    SharedQuestionReported event,
    Emitter<FriendQuestionState> emit,
  ) async {
    final sharedBy = state.sharedBy;
    if (sharedBy == null ||
        state.reportStatus == QuestionReportStatus.sending ||
        state.isRemoving) {
      return;
    }
    emit(state.copyWith(reportStatus: QuestionReportStatus.sending));
    final answer = _attempt(
      () => reportSharedQuestion(
        friendId: sharedBy.friendId,
        questionId: state.questionId,
        reason: event.reason,
        note: event.note,
      ),
      'Reporting a shared question',
    );
    _reportAnswered = answer;
    final failure = await answer;
    emit(failure == null
        ? state.copyWith(reportStatus: QuestionReportStatus.sent)
        : state.copyWith(
            reportStatus: QuestionReportStatus.unsent,
            isReportRefusedForGood: _isRefusedForGood(failure) ? true : null,
            errorMessage: failure.message,
          ));
  }

  /// Whether trying the report again won't fix [failure]: the share has
  /// ended (404), or the day's reports are used up (429).
  static bool _isRefusedForGood(Failure failure) =>
      failure is RefusedFailure &&
      (failure.statusCode == 404 || failure.statusCode == 429);

  /// Blocking ends every share between the two, this question's included.
  Future<void> _onFriendBlocked(
    FriendBlocked event,
    Emitter<FriendQuestionState> emit,
  ) async {
    final sharedBy = state.sharedBy;
    if (sharedBy == null || state.isBlocking || state.exit != null) return;
    emit(state.copyWith(isBlocking: true));
    final failure = await _attempt(
      () => blockFriend(sharedBy.friendId),
      'Blocking the friend who shared a question',
    );
    emit(failure == null
        ? state.copyWith(isBlocking: false, exit: FriendQuestionExit.blocked)
        : state.copyWith(isBlocking: false, errorMessage: failure.message));
  }

  /// Runs [action], and answers with how it failed, or null when it worked.
  Future<Failure?> _attempt(
    Future<void> Function() action,
    String what,
  ) async {
    try {
      await action();
      return null;
    } on Failure catch (f, stackTrace) {
      AppLogger.error('$what failed', error: f, stackTrace: stackTrace);
      return f;
    } catch (e, stackTrace) {
      AppLogger.error('$what failed unexpectedly',
          error: e, stackTrace: stackTrace);
      return UnknownFailure(FriendsMessages.somethingWentWrong);
    }
  }
}
