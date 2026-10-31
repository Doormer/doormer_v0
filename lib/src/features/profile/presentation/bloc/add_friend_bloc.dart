import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/found_student.dart';
import '../../domain/entity/friend_request.dart';
import '../../domain/usecase/find_student_usecase.dart';
import '../../domain/usecase/forget_invite_code_usecase.dart';
import '../../domain/usecase/load_friend_profile_usecase.dart';
import '../../domain/usecase/reset_friend_code_usecase.dart';
import '../../domain/usecase/send_friend_request_usecase.dart';
import '../../domain/usecase/unblock_student_usecase.dart';
import '../../utils/friend_codes.dart';

part 'add_friend_event.dart';
part 'add_friend_state.dart';

/// Add a friend: the student's own code, which they can reset, and finding
/// another student's code, with what can be done next.
///
/// Opened from an invite link, it forgets the kept code and checks it at
/// once, or asks for setup first when the student has no friend profile.
class AddFriendBloc extends Bloc<AddFriendEvent, AddFriendState> {
  static const _somethingWentWrong = 'Something went wrong. Try again.';

  final LoadFriendProfileUseCase loadProfile;
  final FindStudentUseCase findStudent;
  final SendFriendRequestUseCase sendRequest;
  final UnblockStudentUseCase unblockStudent;
  final ResetFriendCodeUseCase resetCode;
  final ForgetInviteCodeUseCase forgetInviteCode;

  /// The code of the invite link the page was opened from, with no dash. A
  /// request to its owner counts as sent by link, even after the student
  /// types the code again.
  String? _inviteCode;

  AddFriendBloc({
    required this.loadProfile,
    required this.findStudent,
    required this.sendRequest,
    required this.unblockStudent,
    required this.resetCode,
    required this.forgetInviteCode,
  }) : super(const AddFriendLoading()) {
    on<AddFriendStarted>(_onStarted);
    on<FriendCodeSubmitted>(_onCodeSubmitted);
    on<FriendRequestSent>(_onRequestSent);
    on<FoundStudentUnblocked>(_onFoundStudentUnblocked);
    on<FriendCodeReset>(_onCodeReset);
  }

  Future<void> _onStarted(
    AddFriendStarted event,
    Emitter<AddFriendState> emit,
  ) async {
    final inviteCode = event.inviteCode;
    if (inviteCode != null) {
      _inviteCode = FriendCodes.normalise(inviteCode);
      try {
        await forgetInviteCode();
      } catch (e, stackTrace) {
        AppLogger.error('The kept invite code could not be forgotten',
            error: e, stackTrace: stackTrace);
      }
    }

    if (state is! AddFriendLoading) emit(const AddFriendLoading());
    try {
      final profile = await loadProfile();
      if (!profile.hasProfile) {
        emit(AddFriendNeedsSetup(inviteCode: inviteCode));
        return;
      }
      if (profile.friendsTurnedOff) {
        emit(const AddFriendTurnedOff());
        return;
      }
      emit(AddFriendReady(friendCode: profile.friendCode));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Add a friend failed to load',
          error: f, stackTrace: stackTrace);
      emit(AddFriendError(f.message));
      return;
    } catch (e, stackTrace) {
      AppLogger.error('Add a friend failed to load unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(const AddFriendError(FriendsMessages.couldNotLoadFriends));
      return;
    }

    if (inviteCode != null) {
      await _find(emit, inviteCode);
    }
  }

  Future<void> _onCodeSubmitted(
    FriendCodeSubmitted event,
    Emitter<AddFriendState> emit,
  ) =>
      _find(emit, event.typed);

  /// Looks up [typed], read without regard to case, spaces or dashes. A code
  /// that can't be anyone's is never looked up. The invite's code counts as
  /// from the invite link, however it got into the box.
  Future<void> _find(Emitter<AddFriendState> emit, String typed) async {
    final ready = state;
    if (ready is! AddFriendReady || ready.isFinding) return;
    final code = FriendCodes.normalise(typed);
    if (!FriendCodes.isWellFormed(code)) {
      emit(ready.withNoOneFound(FriendsMessages.codeNotFound));
      return;
    }

    emit(ready.withNoOneFound(null).copyWith(isFinding: true));
    try {
      final found = await findStudent(code);
      final latest = state;
      if (latest is! AddFriendReady) return;
      emit(latest.copyWith(
        isFinding: false,
        found: found,
        foundCode: code,
        via:
            code == _inviteCode ? FriendRequestVia.link : FriendRequestVia.code,
      ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Finding a friend code failed',
          error: f, stackTrace: stackTrace);
      _emitNoOneFound(emit, f.message);
    } catch (e, stackTrace) {
      AppLogger.error('Finding a friend code failed unexpectedly',
          error: e, stackTrace: stackTrace);
      _emitNoOneFound(emit, _somethingWentWrong);
    }
  }

  void _emitNoOneFound(Emitter<AddFriendState> emit, String message) {
    final latest = state;
    if (latest is! AddFriendReady) return;
    emit(latest.withNoOneFound(message));
  }

  /// Send request, or Accept, which sends a request back.
  Future<void> _onRequestSent(
    FriendRequestSent event,
    Emitter<AddFriendState> emit,
  ) =>
      _act(
        emit,
        'Sending a friend request',
        (ready) async {
          final result = await sendRequest(ready.foundCode!, ready.via);
          return result == SendFriendRequestResult.nowFriends
              ? FriendRelation.friends
              : FriendRelation.requestSent;
        },
        failureMessage: _sendFailureMessage,
      );

  /// What a send that failed says. Accept sends a request back, which the
  /// API turns into an accept, and an accept is refused while either of the
  /// two has 100 friends: the send's own words would blame the student alone.
  static String _sendFailureMessage(Failure failure, FriendRelation relation) =>
      failure is RefusedFailure &&
              failure.statusCode == 409 &&
              relation == FriendRelation.requestReceived
          ? FriendsMessages.oneOfYouHasHundredFriends
          : failure.message;

  Future<void> _onFoundStudentUnblocked(
    FoundStudentUnblocked event,
    Emitter<AddFriendState> emit,
  ) =>
      _act(emit, 'Unblocking a student', (ready) async {
        await unblockStudent(ready.found!.student.friendId);
        return FriendRelation.none;
      });

  /// Runs [action] on the found student, and shows how the two are
  /// connected after it. When it fails, [failureMessage], given how the two
  /// were connected, words the failure in place of its own message.
  Future<void> _act(
    Emitter<AddFriendState> emit,
    String what,
    Future<FriendRelation> Function(AddFriendReady ready) action, {
    String Function(Failure failure, FriendRelation relation)? failureMessage,
  }) async {
    final ready = state;
    if (ready is! AddFriendReady || ready.isActing) return;
    final found = ready.found;
    if (found == null || ready.foundCode == null) return;

    emit(ready.copyWith(isActing: true));
    FriendRelation? relation;
    String? errorMessage;
    try {
      relation = await action(ready);
    } on Failure catch (f, stackTrace) {
      AppLogger.error('$what failed', error: f, stackTrace: stackTrace);
      errorMessage = failureMessage?.call(f, found.relation) ?? f.message;
    } catch (e, stackTrace) {
      AppLogger.error('$what failed unexpectedly',
          error: e, stackTrace: stackTrace);
      errorMessage = _somethingWentWrong;
    }

    final latest = state;
    if (latest is! AddFriendReady) return;
    final stillShown = latest.found?.student == found.student;
    emit(latest.copyWith(
      isActing: false,
      found: relation != null && stillShown
          ? FoundStudent(student: found.student, relation: relation)
          : null,
      errorMessage: errorMessage,
    ));
  }

  /// Makes a new code. The page has already warned that the old one and its
  /// invite links stop working.
  Future<void> _onCodeReset(
    FriendCodeReset event,
    Emitter<AddFriendState> emit,
  ) async {
    final ready = state;
    if (ready is! AddFriendReady || ready.isResettingCode) return;
    emit(ready.copyWith(isResettingCode: true));

    String? friendCode;
    String? errorMessage;
    try {
      friendCode = (await resetCode()).friendCode;
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Resetting the friend code failed',
          error: f, stackTrace: stackTrace);
      errorMessage = f.message;
    } catch (e, stackTrace) {
      AppLogger.error('Resetting the friend code failed unexpectedly',
          error: e, stackTrace: stackTrace);
      errorMessage = _somethingWentWrong;
    }

    final latest = state;
    if (latest is! AddFriendReady) return;
    emit(latest.copyWith(
      isResettingCode: false,
      friendCode: friendCode,
      errorMessage: errorMessage,
    ));
  }
}
