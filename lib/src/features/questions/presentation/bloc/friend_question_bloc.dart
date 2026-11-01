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

  FriendQuestionBloc({
    required this.removeSharedQuestion,
    required this.reportSharedQuestion,
    required this.blockFriend,
  }) : super(const FriendQuestionState()) {
    on<FriendQuestionStarted>(_onStarted);
    on<SharedQuestionRemoved>(_onRemoved);
    on<SharedQuestionReportOpened>(_onReportOpened);
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

  Future<void> _onRemoved(
    SharedQuestionRemoved event,
    Emitter<FriendQuestionState> emit,
  ) async {
    if (state.isRemoving || state.exit != null) return;
    emit(state.copyWith(isRemoving: true));
    final errorMessage = await _attempt(
      () => removeSharedQuestion(state.questionId),
      'Removing a shared question',
    );
    emit(errorMessage == null
        ? state.copyWith(isRemoving: false, exit: FriendQuestionExit.removed)
        : state.copyWith(isRemoving: false, errorMessage: errorMessage));
  }

  void _onReportOpened(
    SharedQuestionReportOpened event,
    Emitter<FriendQuestionState> emit,
  ) {
    emit(state.copyWith(reportStatus: QuestionReportStatus.unsent));
  }

  /// Sends the report with the question. The share must still stand when it
  /// arrives, so the sheet offers Block only after this.
  Future<void> _onReported(
    SharedQuestionReported event,
    Emitter<FriendQuestionState> emit,
  ) async {
    final sharedBy = state.sharedBy;
    if (sharedBy == null ||
        state.reportStatus == QuestionReportStatus.sending) {
      return;
    }
    emit(state.copyWith(reportStatus: QuestionReportStatus.sending));
    final errorMessage = await _attempt(
      () => reportSharedQuestion(
        friendId: sharedBy.friendId,
        questionId: state.questionId,
        reason: event.reason,
        note: event.note,
      ),
      'Reporting a shared question',
    );
    emit(errorMessage == null
        ? state.copyWith(reportStatus: QuestionReportStatus.sent)
        : state.copyWith(
            reportStatus: QuestionReportStatus.unsent,
            errorMessage: errorMessage,
          ));
  }

  /// Blocking ends every share between the two, this question's included.
  Future<void> _onFriendBlocked(
    FriendBlocked event,
    Emitter<FriendQuestionState> emit,
  ) async {
    final sharedBy = state.sharedBy;
    if (sharedBy == null || state.isBlocking || state.exit != null) return;
    emit(state.copyWith(isBlocking: true));
    final errorMessage = await _attempt(
      () => blockFriend(sharedBy.friendId),
      'Blocking the friend who shared a question',
    );
    emit(errorMessage == null
        ? state.copyWith(isBlocking: false, exit: FriendQuestionExit.blocked)
        : state.copyWith(isBlocking: false, errorMessage: errorMessage));
  }

  /// Runs [action], and answers with why it failed, or null when it worked.
  Future<String?> _attempt(
    Future<void> Function() action,
    String what,
  ) async {
    try {
      await action();
      return null;
    } on Failure catch (f, stackTrace) {
      AppLogger.error('$what failed', error: f, stackTrace: stackTrace);
      return f.message;
    } catch (e, stackTrace) {
      AppLogger.error('$what failed unexpectedly',
          error: e, stackTrace: stackTrace);
      return FriendsMessages.somethingWentWrong;
    }
  }
}
