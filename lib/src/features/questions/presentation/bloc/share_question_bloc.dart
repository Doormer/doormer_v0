import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecase/load_friends_to_share_with_usecase.dart';
import '../../domain/usecase/share_question_usecase.dart';
import '../../domain/usecase/stop_sharing_question_usecase.dart';

part 'share_question_event.dart';
part 'share_question_state.dart';

/// Sharing the student's own solved question with friends: who it is shared
/// with, the sheet of friends to tick and send it to, and Stop sharing.
///
/// Handlers run concurrently, so each applies its answer to the state as it
/// stands after the await, never to the one before it.
class ShareQuestionBloc extends Bloc<ShareQuestionEvent, ShareQuestionState> {
  /// The most friends one send shares with, as the API allows.
  static const maxFriendsPerSend = 10;

  final LoadFriendsToShareWithUseCase loadFriends;
  final ShareQuestionUseCase shareQuestion;
  final StopSharingQuestionUseCase stopSharing;

  ShareQuestionBloc({
    required this.loadFriends,
    required this.shareQuestion,
    required this.stopSharing,
  }) : super(const ShareQuestionState()) {
    on<ShareQuestionStarted>(_onStarted);
    on<ShareSheetOpened>(_onSheetOpened);
    on<ShareFriendToggled>(_onFriendToggled);
    on<ShareSent>(_onSent);
    on<SharingStopped>(_onSharingStopped);
  }

  void _onStarted(
    ShareQuestionStarted event,
    Emitter<ShareQuestionState> emit,
  ) {
    emit(ShareQuestionState(
      questionId: event.questionId,
      sharedWith: event.sharedWith,
    ));
  }

  /// Reads the friends afresh each time the sheet opens, with no one ticked.
  ///
  /// While a send is on its way, the sheet stays as it is, so a sheet reopened
  /// meanwhile shows the send, and then its answer. The friends fill the sheet
  /// only if it is still loading when they arrive, or showing a load that
  /// failed. A load that answers after another load has filled the sheet with
  /// friends, or after a send has started or closed it, changes nothing.
  Future<void> _onSheetOpened(
    ShareSheetOpened event,
    Emitter<ShareQuestionState> emit,
  ) async {
    if (state.sheet case ShareSheetReady(isSending: true)) return;
    emit(state.copyWith(sheet: const ShareSheetLoading()));
    final sheet = await _readFriends(keepTicked: const {});
    if (state.sheet case ShareSheetLoading() || ShareSheetError()) {
      emit(state.copyWith(sheet: sheet));
    }
  }

  /// A friend the question is already shared with stays ticked, and no more
  /// than [maxFriendsPerSend] can be ticked.
  void _onFriendToggled(
    ShareFriendToggled event,
    Emitter<ShareQuestionState> emit,
  ) {
    final sheet = state.sheet;
    if (sheet is! ShareSheetReady ||
        sheet.isSending ||
        state.isSharedWith(event.friendId)) {
      return;
    }
    final ticked = {...sheet.ticked};
    if (!ticked.remove(event.friendId)) {
      if (sheet.isFull) return;
      ticked.add(event.friendId);
    }
    emit(state.copyWith(sheet: sheet.copyWith(ticked: ticked)));
  }

  /// Shares with the friends ticked, in the order the sheet lists them, and
  /// closes the sheet. A refused share shares with no one.
  ///
  /// While it sends, nothing ticks, sends or reopens the sheet, and a friends
  /// load that answers meanwhile leaves it alone. So the sheet read before the
  /// request is still the one in the state when it answers.
  Future<void> _onSent(
      ShareSent event, Emitter<ShareQuestionState> emit) async {
    final sheet = state.sheet;
    if (sheet is! ShareSheetReady || sheet.isSending || sheet.ticked.isEmpty) {
      return;
    }
    emit(state.copyWith(sheet: sheet.copyWith(isSending: true)));
    final friendIds = [
      for (final friend in sheet.friends)
        if (sheet.ticked.contains(friend.friendId)) friend.friendId,
    ];
    Failure? failure;
    try {
      final sharedWith = await shareQuestion(state.questionId, friendIds);
      emit(state.copyWith(
        sharedWith: sharedWith,
        sheet: const ShareSheetClosed(),
        notice: ShareNotice.shared,
      ));
      return;
    } on Failure catch (f, stackTrace) {
      failure = f;
      AppLogger.error('Sharing a question failed',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      AppLogger.error('Sharing a question failed unexpectedly',
          error: e, stackTrace: stackTrace);
    }
    // A 404 means someone ticked is no longer a friend. The sheet then lists
    // the friends as they are now, so Send again shares with those left.
    final friendLeft = failure is RefusedFailure && failure.statusCode == 404;
    final next = friendLeft
        ? await _readFriends(keepTicked: sheet.ticked)
        : sheet.copyWith(isSending: false);
    emit(state.copyWith(
      sheet: next,
      errorMessage: failure?.message ?? FriendsMessages.somethingWentWrong,
    ));
  }

  Future<void> _onSharingStopped(
    SharingStopped event,
    Emitter<ShareQuestionState> emit,
  ) async {
    if (state.isStopping || state.sharedWith.isEmpty) return;
    emit(state.copyWith(isStopping: true));
    try {
      await stopSharing(state.questionId);
      emit(state.copyWith(
        sharedWith: const [],
        isStopping: false,
        notice: ShareNotice.stopped,
      ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Stopping sharing failed',
          error: f, stackTrace: stackTrace);
      emit(state.copyWith(isStopping: false, errorMessage: f.message));
    } catch (e, stackTrace) {
      AppLogger.error('Stopping sharing failed unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        isStopping: false,
        errorMessage: FriendsMessages.somethingWentWrong,
      ));
    }
  }

  /// The sheet with the student's friends, still ticked where they were in
  /// [keepTicked]; or why there is no one to tick.
  Future<ShareSheet> _readFriends({required Set<String> keepTicked}) async {
    try {
      final friends = await loadFriends();
      if (friends.isEmpty) {
        return const ShareSheetUnavailable(FriendsMessages.addFriendsToShare);
      }
      return ShareSheetReady(
        friends: friends,
        ticked: {
          for (final friend in friends)
            if (keepTicked.contains(friend.friendId)) friend.friendId,
        },
      );
    } on RefusedFailure catch (f, stackTrace) {
      AppLogger.error('Friends to share with were refused',
          error: f, stackTrace: stackTrace);
      // Before setup (409), or with friends turned off (403), there is no one
      // to share with, and trying again won't change that.
      return f.statusCode == 409 || f.statusCode == 403
          ? ShareSheetUnavailable(f.message)
          : ShareSheetError(f.message);
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Friends to share with failed to load',
          error: f, stackTrace: stackTrace);
      return ShareSheetError(f.message);
    } catch (e, stackTrace) {
      AppLogger.error('Friends to share with failed unexpectedly',
          error: e, stackTrace: stackTrace);
      return const ShareSheetError(FriendsMessages.couldNotLoadFriends);
    }
  }
}
