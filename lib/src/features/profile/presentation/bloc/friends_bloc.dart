import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/friend_profile.dart';
import '../../domain/entity/friend_request.dart';
import '../../domain/entity/report_reason.dart';
import '../../domain/usecase/accept_friend_request_usecase.dart';
import '../../domain/usecase/block_student_usecase.dart';
import '../../domain/usecase/decline_friend_request_usecase.dart';
import '../../domain/usecase/load_friend_profile_usecase.dart';
import '../../domain/usecase/load_friend_requests_usecase.dart';
import '../../domain/usecase/load_friends_usecase.dart';
import '../../domain/usecase/remove_friend_usecase.dart';
import '../../domain/usecase/report_student_usecase.dart';

part 'friends_event.dart';
part 'friends_state.dart';

/// Everything Profile shows of friends, as read from the API.
typedef _FriendsRead = ({
  FriendProfile profile,
  List<FriendRequest> requests,
  List<FriendSummary> friends,
});

/// What Profile shows of friends: the student's friend profile, the requests
/// waiting for them, and their friends; and the answers, removals, blocks and
/// reports made there.
///
/// After every load, and after every action, it reads all three afresh, so
/// the page always shows what the API holds, and tells
/// [WaitingFriendRequestsBloc] how many requests are waiting.
///
/// Handlers run concurrently, so each applies its answer to the state as it
/// stands after the await, never to the one before it.
class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  static const _somethingWentWrong = 'Something went wrong. Try again.';

  final LoadFriendProfileUseCase loadProfile;
  final LoadFriendRequestsUseCase loadRequests;
  final LoadFriendsUseCase loadFriends;
  final AcceptFriendRequestUseCase acceptRequest;
  final DeclineFriendRequestUseCase declineRequest;
  final RemoveFriendUseCase removeFriend;
  final BlockStudentUseCase blockStudent;
  final ReportStudentUseCase reportStudent;
  final WaitingFriendRequestsBloc waitingRequests;

  FriendsBloc({
    required this.loadProfile,
    required this.loadRequests,
    required this.loadFriends,
    required this.acceptRequest,
    required this.declineRequest,
    required this.removeFriend,
    required this.blockStudent,
    required this.reportStudent,
    required this.waitingRequests,
  }) : super(const FriendsLoading()) {
    on<FriendsStarted>(_onStarted);
    on<FriendsRetried>(_onRetried);
    on<FriendsRefreshRequested>(_onRefreshRequested);
    on<FriendRequestAccepted>(_onRequestAccepted);
    on<FriendRequestDeclined>(_onRequestDeclined);
    on<FriendRemoved>(_onFriendRemoved);
    on<StudentBlocked>(_onStudentBlocked);
    on<ReportOpened>(_onReportOpened);
    on<StudentReported>(_onStudentReported);
  }

  Future<void> _onStarted(FriendsStarted event, Emitter<FriendsState> emit) =>
      _load(emit);

  Future<void> _onRetried(FriendsRetried event, Emitter<FriendsState> emit) =>
      _load(emit);

  /// Reads everything again behind what is on screen. Quiet: no spinner, and
  /// a failure leaves the page as it was. The answer is dropped if anything
  /// changed while it was on its way.
  ///
  /// After a failed load, perhaps one made out of sight before the first
  /// visit, it tries again as Try again does instead.
  Future<void> _onRefreshRequested(
    FriendsRefreshRequested event,
    Emitter<FriendsState> emit,
  ) async {
    final opened = state;
    if (opened is FriendsError) {
      await _load(emit);
      return;
    }
    if (opened is FriendsLoading) return;
    try {
      final read = await _read();
      if (state != opened) return;
      _emitRead(emit, read, keeping: opened is FriendsReady ? opened : null);
    } catch (e, stackTrace) {
      AppLogger.error('Friends failed to refresh',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onRequestAccepted(
    FriendRequestAccepted event,
    Emitter<FriendsState> emit,
  ) =>
      _answer(
        emit,
        event.requestId,
        () => acceptRequest(event.requestId),
        'Accepting a friend request',
      );

  Future<void> _onRequestDeclined(
    FriendRequestDeclined event,
    Emitter<FriendsState> emit,
  ) =>
      _answer(
        emit,
        event.requestId,
        () => declineRequest(event.requestId),
        'Declining a friend request',
      );

  Future<void> _onFriendRemoved(
    FriendRemoved event,
    Emitter<FriendsState> emit,
  ) =>
      _change(
        emit,
        event.friendId,
        () => removeFriend(event.friendId),
        'Removing a friend',
      );

  Future<void> _onStudentBlocked(
    StudentBlocked event,
    Emitter<FriendsState> emit,
  ) =>
      _change(
        emit,
        event.friendId,
        () => blockStudent(event.friendId),
        'Blocking a student',
      );

  void _onReportOpened(ReportOpened event, Emitter<FriendsState> emit) {
    final ready = state;
    if (ready is! FriendsReady) return;
    emit(ready.copyWith(reportStatus: ReportStatus.unsent));
  }

  Future<void> _onStudentReported(
    StudentReported event,
    Emitter<FriendsState> emit,
  ) async {
    final ready = state;
    if (ready is! FriendsReady || ready.reportStatus == ReportStatus.sending) {
      return;
    }
    emit(ready.copyWith(reportStatus: ReportStatus.sending));
    final errorMessage = await _attempt(
      () => reportStudent(
        event.friendId,
        reason: event.reason,
        note: event.note,
      ),
      'Reporting a student',
    );
    final latest = state;
    if (latest is! FriendsReady) return;
    emit(latest.copyWith(
      reportStatus:
          errorMessage == null ? ReportStatus.sent : ReportStatus.unsent,
      errorMessage: errorMessage,
    ));
  }

  /// Accepts or declines one request. Its buttons wait until the lists have
  /// been read again.
  Future<void> _answer(
    Emitter<FriendsState> emit,
    String requestId,
    Future<Object?> Function() send,
    String what,
  ) async {
    final ready = state;
    if (ready is! FriendsReady ||
        ready.answeringRequestIds.contains(requestId)) {
      return;
    }
    emit(ready.copyWith(
      answeringRequestIds: {...ready.answeringRequestIds, requestId},
    ));
    final errorMessage = await _attempt(send, what);
    await _readAfterAction(
      emit,
      errorMessage: errorMessage,
      finish: (latest) => latest.copyWith(
        answeringRequestIds: {...latest.answeringRequestIds}..remove(requestId),
      ),
    );
  }

  /// Removes or blocks one student. Their row waits until the lists have been
  /// read again.
  Future<void> _change(
    Emitter<FriendsState> emit,
    String friendId,
    Future<Object?> Function() send,
    String what,
  ) async {
    final ready = state;
    if (ready is! FriendsReady || ready.changingFriendIds.contains(friendId)) {
      return;
    }
    emit(ready.copyWith(
      changingFriendIds: {...ready.changingFriendIds, friendId},
    ));
    final errorMessage = await _attempt(send, what);
    await _readAfterAction(
      emit,
      errorMessage: errorMessage,
      finish: (latest) => latest.copyWith(
        changingFriendIds: {...latest.changingFriendIds}..remove(friendId),
      ),
    );
  }

  /// Runs [action], and answers with why it failed, or null when it worked.
  Future<String?> _attempt(
    Future<Object?> Function() action,
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
      return _somethingWentWrong;
    }
  }

  /// Reads everything again after an action, whether it worked or not: a
  /// request that expired, or a friend who left, goes from the page either
  /// way. [finish] takes the action's marker off the latest state.
  Future<void> _readAfterAction(
    Emitter<FriendsState> emit, {
    required String? errorMessage,
    required FriendsReady Function(FriendsReady latest) finish,
  }) async {
    _FriendsRead? read;
    try {
      read = await _read();
    } catch (e, stackTrace) {
      AppLogger.error('Friends failed to reload after an action',
          error: e, stackTrace: stackTrace);
    }
    final latest = state;
    if (latest is! FriendsReady) return;
    final finished = finish(latest);
    if (read == null) {
      emit(finished.copyWith(errorMessage: errorMessage));
      return;
    }
    _emitRead(emit, read, keeping: finished, errorMessage: errorMessage);
  }

  /// The spinner, then the page, or why it could not load.
  Future<void> _load(Emitter<FriendsState> emit) async {
    if (state is! FriendsLoading) emit(const FriendsLoading());
    try {
      _emitRead(emit, await _read());
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Friends failed to load',
          error: f, stackTrace: stackTrace);
      emit(FriendsError(f.message));
    } catch (e, stackTrace) {
      AppLogger.error('Friends failed to load unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(const FriendsError(FriendsMessages.couldNotLoadFriends));
    }
  }

  /// The profile, then the requests and friends. Before setup, or with
  /// friends turned off, there are no requests or friends to read.
  Future<_FriendsRead> _read() async {
    final profile = await loadProfile();
    if (!profile.hasProfile || profile.friendsTurnedOff) {
      return (
        profile: profile,
        requests: <FriendRequest>[],
        friends: <FriendSummary>[]
      );
    }
    final requests = await loadRequests();
    final friends = await loadFriends();
    return (profile: profile, requests: requests, friends: friends);
  }

  /// Shows what was read, keeping the markers of actions still on their way
  /// from [keeping], and counts the waiting requests.
  void _emitRead(
    Emitter<FriendsState> emit,
    _FriendsRead read, {
    FriendsReady? keeping,
    String? errorMessage,
  }) {
    final FriendsState next;
    if (!read.profile.hasProfile) {
      next = const FriendsNotSetUp();
    } else if (read.profile.friendsTurnedOff) {
      next = const FriendsTurnedOff();
    } else {
      next = FriendsReady(
        profile: read.profile,
        requests: read.requests,
        friends: read.friends,
        answeringRequestIds: keeping?.answeringRequestIds ?? const {},
        changingFriendIds: keeping?.changingFriendIds ?? const {},
        reportStatus: keeping?.reportStatus ?? ReportStatus.unsent,
        errorMessage: errorMessage,
      );
    }
    emit(next);
    // A read that lands after Profile closed, such as after signing out,
    // leaves the app-wide count alone.
    if (isClosed) return;
    waitingRequests.add(WaitingFriendRequestsCounted(
      next is FriendsReady ? next.requests.length : 0,
    ));
  }
}
